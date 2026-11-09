#!/usr/bin/env python3
"""Final two-channel sEMG pipeline for Resonance/SPEED.

The pipeline uses the existing marker-derived rest baseline and rolling
normalizer. Its output is a relative activity index, not MVC-normalized force.

Offline:
  python final_emg_interpreter.py analyze recording.h5 calib/emg_baseline.json

Resonance SPEED Code field:
  import os, sys
  root = os.environ["RESONANCE_DIR"]
  sys.path.insert(0, os.path.join(root, "mulines"))
  from final_emg_interpreter import build_speed_pipeline
  build_speed_pipeline(os.path.join(root, "calib", "emg_baseline.json"))
"""
from __future__ import annotations

import argparse
import csv
import json
import math
from dataclasses import asdict, replace
from pathlib import Path
from typing import Any

import numpy as np

from adaptive_normalizer import (
    AdaptiveEMGFrame,
    AdaptiveEMGInterpreter,
    RollingNormalizerConfig,
    load_baseline_report,
)
from emg_interpreter import FilterConfig, load_hdf5_recording
from noise_quality import MainsCancellerConfig, NoiseSuppressor, SignalQualityConfig, SignalQualityMonitor


class FinalEMGInterpreter:
    """Combines band/noise suppression, RMS, rolling normalization and quality gating."""

    def __init__(
        self,
        adaptive: AdaptiveEMGInterpreter,
        *,
        quality_config: SignalQualityConfig | None = None,
        mains_config: MainsCancellerConfig | None = None,
    ) -> None:
        self.adaptive = adaptive
        self.sampling_rate_hz = adaptive.sampling_rate_hz
        # NoiseSuppressor wraps the same stateful Butterworth + notch + RMS
        # frontend used when deriving the baseline report.
        self.mains_config = mains_config or MainsCancellerConfig()
        self.noise_suppressor = NoiseSuppressor(
            self.sampling_rate_hz,
            adaptive.filter_config,
            self.mains_config,
        )
        self.adaptive.front_end = self.noise_suppressor
        self.quality_monitor = SignalQualityMonitor(
            self.sampling_rate_hz,
            quality_config or SignalQualityConfig(),
        )
        self.last_quality_metrics = self.quality_monitor.metrics
        self.minimum_quality = (
            self.quality_monitor.config.minimum_quality
        )

    @classmethod
    def from_baseline_report(
        cls,
        path: str | Path,
        *,
        normalizer_config: RollingNormalizerConfig | None = None,
        quality_config: SignalQualityConfig | None = None,
    ) -> "FinalEMGInterpreter":
        report = load_baseline_report(path)
        adaptive = AdaptiveEMGInterpreter.from_baseline_report(
            path,
            normalizer_config=normalizer_config,
        )
        selected_quality = quality_config or SignalQualityConfig(
            signal_high_hz=min(200.0, float(report["sampling_rate_hz"]) / 2.0 - 1.0)
        )
        mains_config = MainsCancellerConfig(**report.get("config", {}).get("mains_canceller", {}))
        return cls(adaptive, quality_config=selected_quality, mains_config=mains_config)

    def reset(self) -> None:
        self.adaptive.reset()
        self.quality_monitor.reset()
        self.last_quality_metrics = self.quality_monitor.metrics

    def process_block(
        self,
        data: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> AdaptiveEMGFrame:
        matrix = np.asarray(data, dtype=np.float64)
        if matrix.ndim != 2:
            raise ValueError(f"Ожидалась матрица [samples, channels], получено {matrix.shape}")
        if matrix.shape[1] <= max(self.adaptive.indices):
            raise ValueError(
                f"Во входе {matrix.shape[1]} каналов, требуются индексы {self.adaptive.indices}"
            )
        selected = matrix[:, self.adaptive.indices]

        # The adaptive processor runs filtered RMS and baseline/rolling logic.
        frame = self.adaptive.process_block(matrix, timestamps_ns)
        # The monitor observes raw samples independently from the filtered path.
        residual = self.noise_suppressor.last_cancelled_samples
        quality_frame = self.quality_monitor.process(selected, residual, timestamps_ns)
        self.last_quality_metrics = self.quality_monitor.metrics

        left_quality = np.minimum(frame.left_signal_quality, quality_frame.quality[:, 0])
        right_quality = np.minimum(frame.right_signal_quality, quality_frame.quality[:, 1])

        # The adaptive rolling normalizer's profile gate is intentionally not
        # used as a hard game-control gate: a new sensor in manual-threshold
        # mode has no task/rest baseline classification yet. Keep the
        # diagnostic quality score, and require a full runtime quality window,
        # an artifact-free window and finite input. The event detector then estimates its own quiet
        # noise floor and performs onset/release hysteresis.
        finite = np.isfinite(selected)
        left_valid = quality_frame.ready[:, 0] & quality_frame.artifact_free[:, 0] & finite[:, 0]
        right_valid = quality_frame.ready[:, 1] & quality_frame.artifact_free[:, 1] & finite[:, 1]

        return replace(
            frame,
            left_signal_quality=left_quality,
            right_signal_quality=right_quality,
            left_control_valid=left_valid,
            right_control_valid=right_valid,
            left_raw_mains_fraction=quality_frame.raw_mains_fraction[:, 0],
            right_raw_mains_fraction=quality_frame.raw_mains_fraction[:, 1],
            left_residual_mains_fraction=quality_frame.residual_mains_fraction[:, 0],
            right_residual_mains_fraction=quality_frame.residual_mains_fraction[:, 1],
            mains_estimated_frequency_hz=self.noise_suppressor.last_cancellation_frame.estimated_frequency_hz,
            mains_narrowband_fraction=self.noise_suppressor.last_cancellation_frame.narrowband_fraction,
            mains_cancel_enabled=self.noise_suppressor.last_cancellation_frame.enabled,
        )


def analyze_recording(
    recording_path: str | Path,
    baseline_report_path: str | Path,
    output_dir: str | Path,
    *,
    chunk_seconds: float = 1.0,
    output_step_ms: float = 50.0,
    rolling_config: RollingNormalizerConfig | None = None,
    quality_config: SignalQualityConfig | None = None,
) -> dict[str, str]:
    """Run the final streaming pipeline over an existing HDF5 recording."""
    if chunk_seconds <= 0 or output_step_ms <= 0:
        raise ValueError("chunk_seconds и output_step_ms должны быть положительными")
    report = load_baseline_report(baseline_report_path)
    data, labels, fs, timestamps_ns, stream_name = load_hdf5_recording(recording_path)
    if not math.isclose(fs, float(report["sampling_rate_hz"]), rel_tol=0.0, abs_tol=0.01):
        raise ValueError("Частота дискретизации записи не совпадает с baseline report")
    for side in ("left", "right"):
        index = int(report["channels"][side]["channel_index"])
        if index >= data.shape[1]:
            raise ValueError(f"Индекс {side} канала {index} выходит за границы входа")
        expected = str(report["channels"][side]["channel_name"])
        if labels and labels[index] != expected:
            raise ValueError(
                f"Индекс {side} канала {index} содержит {labels[index]!r}, ожидался {expected!r}"
            )

    processor = FinalEMGInterpreter.from_baseline_report(
        baseline_report_path,
        normalizer_config=rolling_config,
        quality_config=quality_config,
    )
    chunk_samples = max(1, int(round(chunk_seconds * fs)))
    frames: list[AdaptiveEMGFrame] = []
    for start in range(0, data.shape[0], chunk_samples):
        end = min(data.shape[0], start + chunk_samples)
        frames.append(processor.process_block(data[start:end], timestamps_ns[start:end]))

    def join(field: str) -> np.ndarray:
        if not frames:
            return np.empty(0, dtype=np.float64)
        return np.concatenate([np.asarray(getattr(frame, field)) for frame in frames])

    fields = (
        "left_activity_index", "right_activity_index", "left_rms", "right_rms",
        "left_excess_rms", "right_excess_rms", "left_reference_rms", "right_reference_rms",
        "left_signal_quality", "right_signal_quality", "left_reference_ready",
        "right_reference_ready", "left_control_valid", "right_control_valid",
        "left_raw_mains_fraction", "right_raw_mains_fraction",
        "left_residual_mains_fraction", "right_residual_mains_fraction",
        "mains_estimated_frequency_hz", "mains_narrowband_fraction", "mains_cancel_enabled",
    )
    values = {field: join(field) for field in fields}
    times_s = timestamps_ns.astype(np.float64) / 1e9

    destination = Path(output_dir).expanduser()
    destination.mkdir(parents=True, exist_ok=True)
    csv_path = destination / "emg_interpreted_50ms.csv"
    summary_path = destination / "emg_interpreter_summary.json"
    plot_path = destination / "emg_interpreter_diagnostics.png"

    step = max(1, int(round(output_step_ms * fs / 1000.0)))
    headers = [
        "time_s", "left_activity_index", "right_activity_index",
        "left_rms_v", "right_rms_v", "left_reference_rms_v", "right_reference_rms_v",
        "left_signal_quality", "right_signal_quality",
        "left_reference_ready", "right_reference_ready",
        "left_control_valid", "right_control_valid",
        "left_raw_mains_fraction", "right_raw_mains_fraction",
        "left_residual_mains_fraction", "right_residual_mains_fraction",
        "mains_estimated_frequency_hz", "mains_narrowband_fraction", "mains_cancel_enabled",
    ]
    numeric_fields = (
        "left_activity_index", "right_activity_index", "left_rms", "right_rms",
        "left_reference_rms", "right_reference_rms",
        "left_signal_quality", "right_signal_quality",
    )
    bool_fields = (
        "left_reference_ready", "right_reference_ready",
        "left_control_valid", "right_control_valid",
    )
    mains_fields = (
        "left_raw_mains_fraction", "right_raw_mains_fraction",
        "left_residual_mains_fraction", "right_residual_mains_fraction",
        "mains_estimated_frequency_hz", "mains_narrowband_fraction",
    )
    canceller_bool_fields = ("mains_cancel_enabled",)
    with csv_path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        for start in range(0, data.shape[0], step):
            end = min(data.shape[0], start + step)
            row: list[Any] = [float(times_s[start])]
            row.extend(float(np.mean(values[field][start:end])) for field in numeric_fields)
            row.extend(bool(np.any(values[field][start:end])) for field in bool_fields)
            row.extend(float(np.mean(values[field][start:end])) for field in mains_fields)
            row.extend(bool(np.any(values[field][start:end])) for field in canceller_bool_fields)
            writer.writerow(row)

    profiles = processor.adaptive.quality_profiles
    monitor_metrics = [metric.to_dict() for metric in processor.last_quality_metrics]
    summary = {
        "schema_version": 1,
        "source_recording": str(Path(recording_path).expanduser()),
        "baseline_report": str(Path(baseline_report_path).expanduser()),
        "stream_name": stream_name,
        "sampling_rate_hz": fs,
        "sample_count": int(data.shape[0]),
        "duration_s": float(data.shape[0] / fs),
        "normalization_semantics": "relative rolling activity index; not MVC and not mechanical force",
        "filter_config": asdict(processor.adaptive.filter_config),
        "rolling_config": asdict(processor.adaptive.normalizer_config),
        "quality_config": asdict(processor.quality_monitor.config),
        "mains_canceller_config": asdict(processor.mains_config),
        "task_activity_validation": report.get("task_activity_validation", {}),
        "runtime_quality_metrics_at_end": monitor_metrics,
        "mains_cancellation": {
            "enabled_fraction": float(np.mean(values["mains_cancel_enabled"])),
            "estimated_frequency_median_hz": float(np.median(values["mains_estimated_frequency_hz"])),
            "narrowband_fraction_median": float(np.median(values["mains_narrowband_fraction"])),
        },
        "channels": {},
    }
    for idx, side in enumerate(("left", "right")):
        profile = profiles[idx]
        activity = values[f"{side}_activity_index"]
        summary["channels"][side] = {
            "channel_name": profile.channel_name,
            "channel_index": profile.channel_index,
            "baseline_status": profile.baseline_status,
            "baseline_quality_score": profile.quality_score,
            "baseline_control_allowed": profile.control_allowed,
            "runtime_quality_median": float(np.median(values[f"{side}_signal_quality"])),
            "control_valid_fraction": float(np.mean(values[f"{side}_control_valid"])),
            "reference_ready_fraction": float(np.mean(values[f"{side}_reference_ready"])),
            "activity_index_median": float(np.median(activity)),
            "activity_index_p95": float(np.percentile(activity, 95.0)),
            "activity_index_max": float(np.max(activity)) if activity.size else 0.0,
            "activity_nonzero_fraction": float(np.mean(activity > 0.0)),
            "raw_mains_fraction_median": float(np.median(values[f"{side}_raw_mains_fraction"])),
            "residual_mains_fraction_median": float(np.median(values[f"{side}_residual_mains_fraction"])),
            "warnings": list(profile.warnings),
        }
    summary["limitations"] = [
        "MVC-калибровка отсутствует; выход является относительным rolling activity index.",
        "control_valid заблокирован, если офлайн-оценка task/rest или динамическое качество недостаточны.",
        "SignalQualityMonitor использует инженерные эвристики, а не медицинскую метрику.",
        "Адаптивный сетевой подавитель удаляет узкую синусоидальную составляющую; он может также подавить реальную ЭМГ-энергию на той же частоте.",
        "Raw/residual mains fractions являются инженерными спектральными оценками, а не клиническими метриками.",
        "Адаптивное подавление не заменяет исправление заземления, референса и контакта электродов.",
        "Частота 500 Гц ограничивает полезную полосу регистрации частотой Найквиста 250 Гц.",
    ]
    with summary_path.open("w", encoding="utf-8") as file:
        json.dump(summary, file, ensure_ascii=False, indent=2)
        file.write("\n")

    _write_plot(times_s, values, summary, plot_path, fs, output_step_ms)
    return {"csv": str(csv_path), "summary": str(summary_path), "plot": str(plot_path)}


def _write_plot(
    times_s: np.ndarray,
    values: dict[str, np.ndarray],
    summary: dict[str, Any],
    destination: Path,
    sampling_rate_hz: float,
    output_step_ms: float,
) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    step = max(1, int(round(output_step_ms * sampling_rate_hz / 1000.0)))
    plot_t: list[float] = []
    decimated: dict[str, list[float]] = {
        key: [] for key in (
            "left_activity_index", "right_activity_index",
            "left_signal_quality", "right_signal_quality",
            "left_control_valid", "right_control_valid",
            "left_raw_mains_fraction", "right_raw_mains_fraction",
            "left_residual_mains_fraction", "right_residual_mains_fraction",
        )
    }
    for start in range(0, len(times_s), step):
        end = min(len(times_s), start + step)
        plot_t.append(float(times_s[start]))
        for key in decimated:
            decimated[key].append(float(np.mean(values[key][start:end])))

    fig, axes = plt.subplots(4, 1, figsize=(15, 12), sharex=True)
    axes[0].plot(plot_t, decimated["left_activity_index"], label="left activity", linewidth=0.85)
    axes[0].plot(plot_t, decimated["right_activity_index"], label="right activity", linewidth=0.85)
    axes[0].set_ylim(-0.03, 1.03)
    axes[0].set_ylabel("Relative index")
    axes[0].set_title("sEMG rolling activity index (not MVC)")
    axes[0].grid(alpha=0.25)
    axes[0].legend(loc="upper right")

    axes[1].plot(plot_t, decimated["left_signal_quality"], label="left quality", linewidth=0.85)
    axes[1].plot(plot_t, decimated["right_signal_quality"], label="right quality", linewidth=0.85)
    axes[1].axhline(0.50, linestyle="--", linewidth=1.0, label="minimum quality")
    axes[1].set_ylim(-0.03, 1.03)
    axes[1].set_ylabel("Quality score")
    axes[1].set_title("Combined baseline and runtime signal quality")
    axes[1].grid(alpha=0.25)
    axes[1].legend(loc="upper right")

    axes[2].step(
        plot_t, decimated["left_control_valid"], where="post",
        label="left_control_valid", linewidth=1.0,
    )
    axes[2].step(
        plot_t, decimated["right_control_valid"], where="post",
        label="right_control_valid", linewidth=1.0,
    )
    axes[2].set_ylim(-0.05, 1.05)
    axes[2].set_ylabel("Control valid (0/1)")
    axes[2].set_title("Control gate (0 = blocked, 1 = allowed)")
    axes[2].grid(alpha=0.25)
    axes[2].legend(loc="upper right")
    axes[2].set_xlabel("Time from beginning of EEG recording, s")

    axes[3].plot(plot_t, decimated["left_raw_mains_fraction"], label="left raw 45–55 Hz", linewidth=0.85)
    axes[3].plot(plot_t, decimated["right_raw_mains_fraction"], label="right raw 45–55 Hz", linewidth=0.85)
    axes[3].plot(plot_t, decimated["left_residual_mains_fraction"], "--", label="left residual 45–55 Hz", linewidth=0.85)
    axes[3].plot(plot_t, decimated["right_residual_mains_fraction"], "--", label="right residual 45–55 Hz", linewidth=0.85)
    axes[3].set_ylim(-0.03, 1.03)
    axes[3].set_ylabel("Mains fraction")
    axes[3].set_title("Raw vs residual mains contamination")
    axes[3].grid(alpha=0.25)
    axes[3].legend(loc="upper right", ncol=2)
    axes[3].set_xlabel("Time from beginning of EEG recording, s")
    fig.tight_layout()
    fig.savefig(destination, dpi=160)
    plt.close(fig)


def build_speed_pipeline(
    baseline_report_path: str | Path,
    *,
    window_seconds: float = 10.0,
) -> None:
    """Register ten runtime outputs in the installed Resonance SPEED engine."""
    import resonance
    import resonance.db as db
    import resonance.si as si
    from resonance.internal import Processor

    report = load_baseline_report(baseline_report_path)
    rolling_config = RollingNormalizerConfig(window_seconds=window_seconds)
    rolling_config.validate(float(report["sampling_rate_hz"]))
    template = FinalEMGInterpreter.from_baseline_report(
        baseline_report_path,
        normalizer_config=rolling_config,
    )

    class _FinalEMGTransform(Processor):
        def __init__(self) -> None:
            self._processor: FinalEMGInterpreter | None = None
            self._output_si: list[Any] = []

        def prepare(self, channels: db.Channels):
            if not isinstance(channels, db.Channels):
                raise TypeError("FinalEMGInterpreter ожидает поток Channels")
            rate = float(channels.SI.samplingRate)
            if not math.isclose(rate, template.sampling_rate_hz, rel_tol=0.0, abs_tol=0.01):
                raise ValueError(
                    f"Частота входа {rate:g} Гц не совпадает с baseline {template.sampling_rate_hz:g} Гц"
                )
            if channels.SI.channels <= max(template.adaptive.indices):
                raise ValueError("Во входном потоке недостаточно каналов для left_p/right_p")
            self._processor = FinalEMGInterpreter.from_baseline_report(
                baseline_report_path,
                normalizer_config=rolling_config,
            )
            self._output_si = [
                si.Channels(channels=1, samplingRate=rate) for _ in range(10)
            ]
            return tuple(self._output_si)

        def online(self, channels: db.Channels):
            if self._processor is None or len(self._output_si) != 10:
                raise RuntimeError("Final EMG pipeline не был подготовлен")
            frame = self._processor.process_block(np.asarray(channels), channels.TS)
            # QuasiGame UDP output: best effort; original ten SPEED outputs unchanged.
            try:
                from emg_game_bridge import publish_frame_to_game
                publish_frame_to_game(frame)
            except Exception as exc:
                if not getattr(self, "_quasigame_error_logged", False):
                    print("QuasiGame UDP bridge error:", repr(exc))
                    self._quasigame_error_logged = True

            outputs = (
                frame.left_activity_index,
                frame.right_activity_index,
                frame.left_signal_quality,
                frame.right_signal_quality,
                frame.left_control_valid.astype(np.float64),
                frame.right_control_valid.astype(np.float64),
                frame.left_raw_mains_fraction,
                frame.right_raw_mains_fraction,
                frame.left_residual_mains_fraction,
                frame.right_residual_mains_fraction,
            )
            return tuple(
                db.Channels(output_si, channels.TS, values.reshape(-1, 1))
                for output_si, values in zip(self._output_si, outputs)
            )

    transform = _FinalEMGTransform()
    outputs = transform.call(resonance.input(0))
    names = (
        "left_activity_index", "right_activity_index",
        "left_signal_quality", "right_signal_quality",
        "left_control_valid", "right_control_valid",
        "left_raw_mains_fraction", "right_raw_mains_fraction",
        "left_residual_mains_fraction", "right_residual_mains_fraction",
    )
    for output, name in zip(outputs, names):
        resonance.createOutput(output, name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    analyze = subparsers.add_parser("analyze", help="Офлайн-анализ существующей HDF5-записи")
    analyze.add_argument("recording", type=Path)
    analyze.add_argument("baseline_report", type=Path)
    analyze.add_argument("--output-dir", type=Path, default=Path("emg_analysis/final"))
    analyze.add_argument("--chunk-seconds", type=float, default=1.0)
    analyze.add_argument("--output-step-ms", type=float, default=50.0)

    args = parser.parse_args()
    if args.command == "analyze":
        outputs = analyze_recording(
            args.recording,
            args.baseline_report,
            args.output_dir,
            chunk_seconds=args.chunk_seconds,
            output_step_ms=args.output_step_ms,
        )
        print(json.dumps(outputs, ensure_ascii=False, indent=2))
        return 0
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
