#!/usr/bin/env python3
"""Rolling sEMG activity normalizer for Resonance/SPEED.

This module reuses the stateful filter/RMS frontend from emg_interpreter.py,
subtracts per-channel resting thresholds from BaselineEstimator, and produces
relative 0..1 activity indices using a robust rolling reference. It does NOT
produce MVC-normalized force estimates.

Offline:
  python adaptive_normalizer.py analyze recording.h5 emg_analysis/baseline_report.json

Resonance SPEED:
  import os, sys
  root = os.environ["RESONANCE_DIR"]
  sys.path.insert(0, os.path.join(root, "mulines"))
  from adaptive_normalizer import build_speed_pipeline
  build_speed_pipeline(os.path.join(root, "calib", "emg_baseline.json"))
"""
from __future__ import annotations

import argparse
import csv
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np

from emg_interpreter import FilterConfig, StreamingEMGFrontEnd, load_hdf5_recording


@dataclass(frozen=True)
class RollingNormalizerConfig:
    """Controls rolling reference adaptation.

    `window_seconds` defines how much recent activity contributes to the
    reference. The reference is the `reference_quantile` percentile of positive
    (above-baseline-threshold) samples, not the raw maximum. A minimum amount of
    activity must be present before a reference can become ready, which rejects
    isolated impulse artifacts.
    """

    window_seconds: float = 10.0
    reference_quantile: float = 95.0
    minimum_active_seconds: float = 0.10
    minimum_burst_ms: float = 50.0
    update_interval_ms: float = 50.0
    reference_attack_seconds: float = 0.50
    reference_release_seconds: float = 4.0
    gap_reset_factor: float = 2.5
    minimum_reference_rms: float = 1e-12
    minimum_control_quality: float = 0.50

    def validate(self, sampling_rate_hz: float) -> None:
        if not math.isfinite(sampling_rate_hz) or sampling_rate_hz <= 0:
            raise ValueError("sampling_rate_hz должен быть положительным")
        if self.window_seconds <= 0 or self.minimum_active_seconds <= 0:
            raise ValueError("Окно и минимальная активность должны быть больше нуля")
        if self.minimum_active_seconds >= self.window_seconds:
            raise ValueError("minimum_active_seconds должен быть меньше window_seconds")
        if not 50.0 <= self.reference_quantile < 100.0:
            raise ValueError("reference_quantile должен находиться в [50, 100)")
        if self.minimum_burst_ms <= 0:
            raise ValueError("minimum_burst_ms должен быть больше нуля")
        if self.minimum_burst_ms / 1000.0 >= self.window_seconds:
            raise ValueError("minimum_burst_ms должен быть меньше rolling window")
        if self.update_interval_ms <= 0:
            raise ValueError("update_interval_ms должен быть больше нуля")
        if self.reference_attack_seconds <= 0 or self.reference_release_seconds <= 0:
            raise ValueError("Времена адаптации должны быть больше нуля")
        if self.gap_reset_factor <= 1.0:
            raise ValueError("gap_reset_factor должен быть больше 1")
        if self.minimum_reference_rms < 0:
            raise ValueError("minimum_reference_rms не может быть отрицательным")
        if not 0.0 <= self.minimum_control_quality <= 1.0:
            raise ValueError("minimum_control_quality должен быть в [0, 1]")


@dataclass(frozen=True)
class ChannelQualityProfile:
    side: str
    channel_name: str
    channel_index: int
    baseline_status: str
    task_to_rest_q95_ratio: float | None
    mains_fraction_45_55_hz: float | None
    interval_q95_cv: float | None
    quality_score: float
    control_allowed: bool
    warnings: tuple[str, ...]


@dataclass
class AdaptiveEMGFrame:
    left_activity_index: np.ndarray
    right_activity_index: np.ndarray
    left_rms: np.ndarray
    right_rms: np.ndarray
    left_excess_rms: np.ndarray
    right_excess_rms: np.ndarray
    left_reference_rms: np.ndarray
    right_reference_rms: np.ndarray
    left_signal_quality: np.ndarray
    right_signal_quality: np.ndarray
    left_reference_ready: np.ndarray
    right_reference_ready: np.ndarray
    left_control_valid: np.ndarray
    right_control_valid: np.ndarray
    left_raw_mains_fraction: np.ndarray
    right_raw_mains_fraction: np.ndarray
    left_residual_mains_fraction: np.ndarray
    right_residual_mains_fraction: np.ndarray
    mains_estimated_frequency_hz: np.ndarray
    mains_narrowband_fraction: np.ndarray
    mains_cancel_enabled: np.ndarray

    @property
    def activity_indices(self) -> np.ndarray:
        return np.column_stack((self.left_activity_index, self.right_activity_index))

    @property
    def signal_quality(self) -> np.ndarray:
        return np.column_stack((self.left_signal_quality, self.right_signal_quality))


class RollingNormalizer:
    """Robust rolling normalization for two nonnegative envelope channels."""

    def __init__(
        self,
        sampling_rate_hz: float,
        config: RollingNormalizerConfig | None = None,
    ) -> None:
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.config = config or RollingNormalizerConfig()
        self.config.validate(self.sampling_rate_hz)
        self._window_samples = max(1, int(round(self.config.window_seconds * self.sampling_rate_hz)))
        self._minimum_active_samples = max(
            1, int(math.ceil(self.config.minimum_active_seconds * self.sampling_rate_hz))
        )
        self._minimum_burst_samples = max(
            1, int(math.ceil(self.config.minimum_burst_ms * self.sampling_rate_hz / 1000.0))
        )
        self._update_samples = max(
            1, int(round(self.config.update_interval_ms * self.sampling_rate_hz / 1000.0))
        )
        self._gap_limit_ns = (
            self.config.gap_reset_factor * 1_000_000_000.0 / self.sampling_rate_hz
        )
        self._attack_alpha = 1.0 - math.exp(
            -self.config.update_interval_ms / 1000.0 / self.config.reference_attack_seconds
        )
        self._release_alpha = 1.0 - math.exp(
            -self.config.update_interval_ms / 1000.0 / self.config.reference_release_seconds
        )
        self.reset()

    def reset(self) -> None:
        # A fixed-size ring buffer retains wall-clock samples, including zeros,
        # so old peaks really leave the rolling window during inactivity.
        self._history = np.zeros((self._window_samples, 2), dtype=np.float64)
        self._write_index = 0
        self._history_count = 0
        self._active_run = np.zeros(2, dtype=np.int64)
        self._pending: list[list[tuple[int, float]]] = [[], []]
        self._reference = np.zeros(2, dtype=np.float64)
        self._samples_since_update = 0
        self._last_timestamp_ns: int | None = None

    def _reset_history(self) -> None:
        self._history.fill(0.0)
        self._write_index = 0
        self._history_count = 0
        self._active_run[:] = 0
        self._pending = [[], []]
        self._reference[:] = 0.0
        self._samples_since_update = 0

    def _update_reference(self) -> None:
        history = self._history if self._history_count >= self._window_samples else self._history[:self._history_count]
        for channel in range(2):
            positive = history[:, channel]
            positive = positive[positive > 0.0]
            if positive.size < self._minimum_active_samples:
                candidate = 0.0
            else:
                candidate = float(np.percentile(positive, self.config.reference_quantile))

            current = self._reference[channel]
            if current <= self.config.minimum_reference_rms and candidate > self.config.minimum_reference_rms:
                # Start the first usable reference without an artificial ramp-up delay.
                updated = candidate
            else:
                alpha = self._attack_alpha if candidate >= current else self._release_alpha
                updated = current + alpha * (candidate - current)
            self._reference[channel] = max(0.0, updated)

    def process(
        self,
        envelope_rms: np.ndarray,
        thresholds_rms: np.ndarray,
        *,
        valid_mask: np.ndarray | None = None,
        timestamps_ns: np.ndarray | None = None,
    ) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """Return (index, excess, reference, ready), each shaped [rows, 2]."""
        envelope = np.asarray(envelope_rms, dtype=np.float64)
        thresholds = np.asarray(thresholds_rms, dtype=np.float64).reshape(-1)
        if envelope.ndim != 2 or envelope.shape[1] != 2:
            raise ValueError(f"Ожидался envelope [samples, 2], получено {envelope.shape}")
        if thresholds.size != 2 or not np.all(np.isfinite(thresholds)) or np.any(thresholds < 0):
            raise ValueError("Нужны два конечных неотрицательных порога")

        count = envelope.shape[0]
        if valid_mask is None:
            valid = np.isfinite(envelope).all(axis=1)
        else:
            valid = np.asarray(valid_mask, dtype=bool).reshape(-1)
            if valid.size != count:
                raise ValueError("valid_mask не совпадает с числом отсчётов")
            valid &= np.isfinite(envelope).all(axis=1)

        timestamps: np.ndarray | None
        if timestamps_ns is None:
            timestamps = None
        else:
            timestamps = np.asarray(timestamps_ns, dtype=np.int64).reshape(-1)
            if timestamps.size != count:
                raise ValueError("timestamps_ns не совпадает с числом отсчётов")

        indices = np.zeros((count, 2), dtype=np.float64)
        excess = np.zeros_like(indices)
        references = np.zeros_like(indices)
        ready = np.zeros((count, 2), dtype=bool)

        for row in range(count):
            if not valid[row]:
                self._reset_history()
                self._last_timestamp_ns = None
                continue

            if timestamps is not None and self._last_timestamp_ns is not None:
                delta = int(timestamps[row]) - self._last_timestamp_ns
                if delta <= 0 or delta > self._gap_limit_ns:
                    self._reset_history()
                    self._last_timestamp_ns = None

            current_excess = np.maximum(envelope[row] - thresholds, 0.0)
            excess[row] = current_excess
            self._history[self._write_index, :] = 0.0
            accepted_activity = np.zeros(2, dtype=bool)
            for channel in range(2):
                value = float(current_excess[channel])
                if value > 0.0:
                    self._active_run[channel] += 1
                    if self._active_run[channel] < self._minimum_burst_samples:
                        self._pending[channel].append((self._write_index, value))
                    elif self._active_run[channel] == self._minimum_burst_samples:
                        # Retroactively accept the leading samples of a burst,
                        # but only after it has persisted for the debounce time.
                        self._pending[channel].append((self._write_index, value))
                        for history_index, pending_value in self._pending[channel]:
                            self._history[history_index, channel] = pending_value
                        self._pending[channel].clear()
                    else:
                        self._history[self._write_index, channel] = value
                        accepted_activity[channel] = True
                else:
                    self._active_run[channel] = 0
                    self._pending[channel].clear()
                accepted_activity[channel] = accepted_activity[channel] or (
                    self._active_run[channel] >= self._minimum_burst_samples
                )

            self._write_index = (self._write_index + 1) % self._window_samples
            self._history_count = min(self._history_count + 1, self._window_samples)
            self._samples_since_update += 1
            if self._samples_since_update >= self._update_samples:
                self._update_reference()
                self._samples_since_update = 0

            references[row] = self._reference
            ready[row] = self._reference > self.config.minimum_reference_rms
            usable = ready[row] & accepted_activity
            if np.any(usable):
                indices[row, usable] = np.clip(
                    current_excess[usable] / self._reference[usable], 0.0, 1.0
                )

            if timestamps is not None:
                self._last_timestamp_ns = int(timestamps[row])

        return indices, excess, references, ready


def _finite_optional(value: Any) -> float | None:
    if value is None:
        return None
    number = float(value)
    return number if math.isfinite(number) else None


def _quality_profile(
    side: str,
    payload: dict[str, Any],
    minimum_control_quality: float = 0.50,
) -> ChannelQualityProfile:
    """Build a conservative, explainable quality score from BaselineEstimator."""
    # Prefer explicit task-block intervals; fall back to microrepeat windows
    # for baseline reports created by older versions.
    ratio = _finite_optional(payload.get("task_block_to_rest_q95_ratio"))
    if ratio is None:
        ratio = _finite_optional(payload.get("task_to_rest_q95_ratio"))
    mains = _finite_optional(payload.get("rest_spectrum_fraction_45_55_hz"))
    interval_cv = _finite_optional(payload.get("interval_q95_cv"))
    status = str(payload.get("status", "unknown"))
    warnings = tuple(str(item) for item in payload.get("warnings", []))

    # Heuristic engineering score, not a probability or clinical quality metric.
    separation_score = float(np.clip((ratio or 0.0) / 1.5, 0.0, 1.0))
    mains_score = (
        0.0 if mains is None
        else 1.0 - float(np.clip(mains / 0.80, 0.0, 1.0))
    )
    stability_score = (
        0.0 if interval_cv is None
        else 1.0 - float(np.clip(interval_cv / 0.50, 0.0, 1.0))
    )
    score = float(np.clip(
        0.50 * separation_score + 0.35 * mains_score + 0.15 * stability_score,
        0.0,
        1.0,
    ))
    control_allowed = (
        status == "candidate_signal_detectable" and score >= minimum_control_quality
    )

    return ChannelQualityProfile(
        side=side,
        channel_name=str(payload.get("channel_name", f"{side}_p")),
        channel_index=int(payload.get("channel_index", -1)),
        baseline_status=status,
        task_to_rest_q95_ratio=ratio,
        mains_fraction_45_55_hz=mains,
        interval_q95_cv=interval_cv,
        quality_score=score,
        control_allowed=control_allowed,
        warnings=warnings,
    )


class AdaptiveEMGInterpreter:
    """Filter two EMG channels and emit rolling activity + signal quality."""

    def __init__(
        self,
        *,
        sampling_rate_hz: float,
        left_channel_index: int,
        right_channel_index: int,
        left_threshold_rms: float,
        right_threshold_rms: float,
        left_quality: ChannelQualityProfile,
        right_quality: ChannelQualityProfile,
        filter_config: FilterConfig | None = None,
        normalizer_config: RollingNormalizerConfig | None = None,
    ) -> None:
        if left_channel_index < 0 or right_channel_index < 0 or left_channel_index == right_channel_index:
            raise ValueError("Индексы левого и правого каналов должны быть разными и неотрицательными")
        thresholds = np.asarray([left_threshold_rms, right_threshold_rms], dtype=np.float64)
        if not np.all(np.isfinite(thresholds)) or np.any(thresholds < 0):
            raise ValueError("Пороги должны быть конечными и неотрицательными")
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.indices = (int(left_channel_index), int(right_channel_index))
        self.thresholds = thresholds
        self.quality_profiles = (left_quality, right_quality)
        self.filter_config = filter_config or FilterConfig()
        self.front_end = StreamingEMGFrontEnd(self.sampling_rate_hz, self.filter_config)
        self.normalizer_config = normalizer_config or RollingNormalizerConfig()
        self.normalizer = RollingNormalizer(self.sampling_rate_hz, self.normalizer_config)

    @classmethod
    def from_baseline_report(
        cls,
        path: str | Path,
        *,
        normalizer_config: RollingNormalizerConfig | None = None,
    ) -> "AdaptiveEMGInterpreter":
        report_path = Path(path).expanduser()
        with report_path.open("r", encoding="utf-8") as file:
            report = json.load(file)
        if report.get("schema_version") != 1:
            raise ValueError("Неподдерживаемая версия baseline_report.json")
        channels = report.get("channels", {})
        if "left" not in channels or "right" not in channels:
            raise ValueError("В baseline_report.json отсутствуют каналы left/right")
        left = channels["left"]
        right = channels["right"]
        config_data = report.get("config", {}).get("filter", {})
        filter_config = FilterConfig.from_dict(config_data)
        sampling_rate = float(report["sampling_rate_hz"])
        selected_normalizer_config = normalizer_config or RollingNormalizerConfig()
        return cls(
            sampling_rate_hz=sampling_rate,
            left_channel_index=int(left["channel_index"]),
            right_channel_index=int(right["channel_index"]),
            left_threshold_rms=float(left["activation_threshold_rms"]),
            right_threshold_rms=float(right["activation_threshold_rms"]),
            left_quality=_quality_profile(
                "left", left, selected_normalizer_config.minimum_control_quality
            ),
            right_quality=_quality_profile(
                "right", right, selected_normalizer_config.minimum_control_quality
            ),
            filter_config=filter_config,
            normalizer_config=selected_normalizer_config,
        )

    def reset(self) -> None:
        self.front_end.reset()
        self.normalizer.reset()

    def process_block(
        self,
        data: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> AdaptiveEMGFrame:
        matrix = np.asarray(data, dtype=np.float64)
        if matrix.ndim != 2:
            raise ValueError(f"Ожидалась матрица [samples, channels], получено {matrix.shape}")
        if matrix.shape[1] <= max(self.indices):
            raise ValueError(
                f"Во входе {matrix.shape[1]} каналов, нужны индексы {self.indices[0]}/{self.indices[1]}"
            )
        selected = matrix[:, self.indices]
        valid_mask = np.isfinite(selected).all(axis=1)
        rms = self.front_end.process(selected, timestamps_ns)
        indices, excess, references, ready = self.normalizer.process(
            rms,
            self.thresholds,
            valid_mask=valid_mask,
            timestamps_ns=timestamps_ns,
        )

        quality_values = np.asarray(
            [profile.quality_score for profile in self.quality_profiles], dtype=np.float64
        )
        quality = np.broadcast_to(quality_values, rms.shape).copy()
        quality[~valid_mask] = 0.0
        control_allowed = np.asarray(
            [profile.control_allowed for profile in self.quality_profiles], dtype=bool
        )
        control_valid = ready & control_allowed[np.newaxis, :] & valid_mask[:, np.newaxis]

        return AdaptiveEMGFrame(
            left_activity_index=indices[:, 0],
            right_activity_index=indices[:, 1],
            left_rms=rms[:, 0],
            right_rms=rms[:, 1],
            left_excess_rms=excess[:, 0],
            right_excess_rms=excess[:, 1],
            left_reference_rms=references[:, 0],
            right_reference_rms=references[:, 1],
            left_signal_quality=quality[:, 0],
            right_signal_quality=quality[:, 1],
            left_reference_ready=ready[:, 0],
            right_reference_ready=ready[:, 1],
            left_control_valid=control_valid[:, 0],
            right_control_valid=control_valid[:, 1],
            left_raw_mains_fraction=np.ones(matrix.shape[0], dtype=np.float64),
            right_raw_mains_fraction=np.ones(matrix.shape[0], dtype=np.float64),
            left_residual_mains_fraction=np.ones(matrix.shape[0], dtype=np.float64),
            right_residual_mains_fraction=np.ones(matrix.shape[0], dtype=np.float64),
            mains_estimated_frequency_hz=np.full(matrix.shape[0], 50.0, dtype=np.float64),
            mains_narrowband_fraction=np.zeros(matrix.shape[0], dtype=np.float64),
            mains_cancel_enabled=np.zeros(matrix.shape[0], dtype=bool),
        )


def load_baseline_report(path: str | Path) -> dict[str, Any]:
    with Path(path).expanduser().open("r", encoding="utf-8") as file:
        report = json.load(file)
    if report.get("calibration_status") != "baseline_only_not_mvc":
        raise ValueError("Ожидался baseline_report без выдуманной MVC-калибровки")
    return report


def analyze_recording(
    recording_path: str | Path,
    baseline_report_path: str | Path,
    output_dir: str | Path,
    *,
    config: RollingNormalizerConfig | None = None,
    output_step_ms: float = 50.0,
    chunk_seconds: float = 1.0,
) -> dict[str, str]:
    """Run the same streaming processor over the existing HDF5 file in chunks."""
    if output_step_ms <= 0 or chunk_seconds <= 0:
        raise ValueError("output_step_ms и chunk_seconds должны быть больше нуля")
    report = load_baseline_report(baseline_report_path)
    data, labels, fs, timestamps, stream_name = load_hdf5_recording(recording_path)
    if not math.isclose(fs, float(report["sampling_rate_hz"]), rel_tol=0.0, abs_tol=0.01):
        raise ValueError("Частота записи не совпадает с baseline_report")

    processor = AdaptiveEMGInterpreter.from_baseline_report(
        baseline_report_path,
        normalizer_config=config,
    )
    chunk_samples = max(1, int(round(chunk_seconds * fs)))
    frames: list[AdaptiveEMGFrame] = []
    for start in range(0, data.shape[0], chunk_samples):
        end = min(data.shape[0], start + chunk_samples)
        frames.append(processor.process_block(data[start:end], timestamps[start:end]))

    def concatenate(field: str) -> np.ndarray:
        return np.concatenate([getattr(frame, field) for frame in frames]) if frames else np.empty(0)

    values = {
        field: concatenate(field)
        for field in (
            "left_activity_index", "right_activity_index", "left_rms", "right_rms",
            "left_excess_rms", "right_excess_rms", "left_reference_rms", "right_reference_rms",
            "left_signal_quality", "right_signal_quality", "left_reference_ready",
            "right_reference_ready", "left_control_valid", "right_control_valid",
        )
    }
    times_s = timestamps.astype(np.float64) / 1e9
    destination = Path(output_dir).expanduser()
    destination.mkdir(parents=True, exist_ok=True)
    csv_path = destination / "rolling_activity_50ms.csv"
    summary_path = destination / "rolling_summary.json"
    plot_path = destination / "rolling_activity.png"

    stride = max(1, int(round(output_step_ms * fs / 1000.0)))
    headers = [
        "time_s", "left_activity_index", "right_activity_index",
        "left_rms_v", "right_rms_v", "left_excess_rms_v", "right_excess_rms_v",
        "left_reference_rms_v", "right_reference_rms_v",
        "left_signal_quality", "right_signal_quality",
        "left_reference_ready", "right_reference_ready",
        "left_control_valid", "right_control_valid",
    ]
    with csv_path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(headers)
        for start in range(0, data.shape[0], stride):
            end = min(data.shape[0], start + stride)
            row: list[Any] = [float(times_s[start])]
            mean_fields = (
                "left_activity_index", "right_activity_index", "left_rms", "right_rms",
                "left_excess_rms", "right_excess_rms", "left_reference_rms", "right_reference_rms",
                "left_signal_quality", "right_signal_quality",
            )
            row.extend(float(np.mean(values[field][start:end])) for field in mean_fields)
            row.extend(bool(np.any(values[field][start:end])) for field in (
                "left_reference_ready", "right_reference_ready", "left_control_valid", "right_control_valid"
            ))
            writer.writerow(row)

    profiles = processor.quality_profiles
    summary = {
        "schema_version": 1,
        "source_recording": str(Path(recording_path).expanduser()),
        "baseline_report": str(Path(baseline_report_path).expanduser()),
        "stream_name": stream_name,
        "sampling_rate_hz": fs,
        "sample_count": int(data.shape[0]),
        "duration_s": float(data.shape[0] / fs),
        "normalizer_config": asdict(processor.normalizer_config),
        "normalization_semantics": "relative rolling activity index; not MVC and not mechanical force",
        "channels": {},
    }
    for idx, side in enumerate(("left", "right")):
        activity = values[f"{side}_activity_index"]
        profile = profiles[idx]
        summary["channels"][side] = {
            "channel_name": profile.channel_name,
            "channel_index": profile.channel_index,
            "baseline_status": profile.baseline_status,
            "quality_score": profile.quality_score,
            "control_allowed": profile.control_allowed,
            "task_to_rest_q95_ratio": profile.task_to_rest_q95_ratio,
            "mains_fraction_45_55_hz": profile.mains_fraction_45_55_hz,
            "reference_ready_fraction": float(np.mean(values[f"{side}_reference_ready"])),
            "control_valid_fraction": float(np.mean(values[f"{side}_control_valid"])),
            "activity_index_max": float(np.max(activity)) if activity.size else 0.0,
            "activity_index_median": float(np.median(activity)) if activity.size else 0.0,
            "activity_nonzero_fraction": float(np.mean(activity > 0.0)) if activity.size else 0.0,
            "warnings": list(profile.warnings),
        }
    with summary_path.open("w", encoding="utf-8") as file:
        json.dump(summary, file, ensure_ascii=False, indent=2)
        file.write("\n")

    _write_activity_plot(times_s, values, profiles, plot_path, fs, output_step_ms)
    return {"csv": str(csv_path), "summary": str(summary_path), "plot": str(plot_path)}


def _write_activity_plot(
    times_s: np.ndarray,
    values: dict[str, np.ndarray],
    profiles: tuple[ChannelQualityProfile, ChannelQualityProfile],
    path: Path,
    sampling_rate_hz: float,
    output_step_ms: float,
) -> None:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    step = max(1, int(round(output_step_ms * sampling_rate_hz / 1000.0)))
    count = int(math.ceil(len(times_s) / step))
    plot_times = np.empty(count, dtype=np.float64)
    left = np.empty(count, dtype=np.float64)
    right = np.empty(count, dtype=np.float64)
    left_reference = np.empty(count, dtype=np.float64)
    right_reference = np.empty(count, dtype=np.float64)
    for idx, start in enumerate(range(0, len(times_s), step)):
        end = min(len(times_s), start + step)
        plot_times[idx] = times_s[start]
        left[idx] = np.mean(values["left_activity_index"][start:end])
        right[idx] = np.mean(values["right_activity_index"][start:end])
        left_reference[idx] = np.mean(values["left_reference_rms"][start:end]) * 1e6
        right_reference[idx] = np.mean(values["right_reference_rms"][start:end]) * 1e6

    fig, axes = plt.subplots(3, 1, figsize=(15, 9), sharex=False)
    axes[0].plot(plot_times, left, label="left_activity_index", linewidth=0.85)
    axes[0].plot(plot_times, right, label="right_activity_index", linewidth=0.85)
    axes[0].set_ylim(-0.03, 1.03)
    axes[0].set_ylabel("Activity index")
    axes[0].set_title("Rolling activity index (relative scale, not MVC)")
    axes[0].grid(alpha=0.25)
    axes[0].legend(loc="upper right")

    axes[1].plot(plot_times, left_reference, label="left rolling reference", linewidth=0.85)
    axes[1].plot(plot_times, right_reference, label="right rolling reference", linewidth=0.85)
    axes[1].set_ylabel("Reference, µV")
    axes[1].set_title("Robust rolling reference (P95 of above-threshold RMS)")
    axes[1].grid(alpha=0.25)
    axes[1].legend(loc="upper right")
    axes[1].set_xlim(axes[0].get_xlim())

    axes[2].bar([0, 1], [profile.quality_score for profile in profiles], tick_label=["left", "right"])
    axes[2].axhline(0.50, linestyle="--", linewidth=1.0, label="minimum control quality")
    axes[2].set_ylim(0.0, 1.0)
    axes[2].set_ylabel("Heuristic quality")
    axes[2].set_title("Recording quality (engineering score, not probability)")
    axes[2].grid(axis="y", alpha=0.25)
    axes[2].legend(loc="upper right")
    axes[-1].set_xlabel("Time from beginning of EEG, s")
    fig.tight_layout()
    fig.savefig(path, dpi=160)
    plt.close(fig)


def build_speed_pipeline(
    baseline_report_path: str | Path,
    *,
    window_seconds: float = 10.0,
) -> None:
    """Declare six live outputs in Resonance SPEED using the Python engine."""
    import resonance
    import resonance.db as db
    import resonance.si as si
    from resonance.internal import Processor

    report = load_baseline_report(baseline_report_path)
    config = RollingNormalizerConfig(window_seconds=window_seconds)
    config.validate(float(report["sampling_rate_hz"]))
    processor_template = AdaptiveEMGInterpreter.from_baseline_report(
        baseline_report_path,
        normalizer_config=config,
    )

    class _RollingEMGResonanceTransform(Processor):
        def __init__(self) -> None:
            self._processor: AdaptiveEMGInterpreter | None = None
            self._output_si: list[Any] = []

        def prepare(self, channels: db.Channels):
            if not isinstance(channels, db.Channels):
                raise TypeError("Rolling EMG ожидает поток Channels")
            sampling_rate = float(channels.SI.samplingRate)
            if not math.isclose(
                sampling_rate,
                processor_template.sampling_rate_hz,
                rel_tol=0.0,
                abs_tol=0.01,
            ):
                raise ValueError(
                    f"Частота входа {sampling_rate:g} Гц не совпадает с baseline "
                    f"{processor_template.sampling_rate_hz:g} Гц"
                )
            if channels.SI.channels <= max(processor_template.indices):
                raise ValueError(
                    f"Во входном потоке {channels.SI.channels} каналов; нужны "
                    f"{processor_template.indices[0]}/{processor_template.indices[1]}"
                )
            self._processor = AdaptiveEMGInterpreter.from_baseline_report(
                baseline_report_path,
                normalizer_config=config,
            )
            self._output_si = [si.Channels(channels=1, samplingRate=sampling_rate) for _ in range(6)]
            return tuple(self._output_si)

        def online(self, channels: db.Channels):
            if self._processor is None or len(self._output_si) != 6:
                raise RuntimeError("Rolling EMG не был подготовлен")
            frame = self._processor.process_block(np.asarray(channels), channels.TS)
            arrays = (
                frame.left_activity_index,
                frame.right_activity_index,
                frame.left_signal_quality,
                frame.right_signal_quality,
                frame.left_control_valid.astype(np.float64),
                frame.right_control_valid.astype(np.float64),
            )
            return tuple(
                db.Channels(output_si, channels.TS, values.reshape(-1, 1))
                for output_si, values in zip(self._output_si, arrays)
            )

    raw = resonance.input(0)
    transform = _RollingEMGResonanceTransform()
    outputs = transform.call(raw)
    names = (
        "left_activity_index",
        "right_activity_index",
        "left_signal_quality",
        "right_signal_quality",
        "left_control_valid",
        "right_control_valid",
    )
    for output, name in zip(outputs, names):
        resonance.createOutput(output, name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    analyze_parser = subparsers.add_parser("analyze", help="Обработать существующую HDF5-запись")
    analyze_parser.add_argument("recording", type=Path)
    analyze_parser.add_argument("baseline_report", type=Path)
    analyze_parser.add_argument("--output-dir", type=Path, default=Path("emg_analysis/rolling"))
    analyze_parser.add_argument("--window-seconds", type=float, default=10.0)
    analyze_parser.add_argument("--quantile", type=float, default=95.0)
    analyze_parser.add_argument("--minimum-active-ms", type=float, default=100.0)
    analyze_parser.add_argument("--minimum-burst-ms", type=float, default=50.0)
    analyze_parser.add_argument("--chunk-seconds", type=float, default=1.0)
    analyze_parser.add_argument("--output-step-ms", type=float, default=50.0)

    args = parser.parse_args()
    config = RollingNormalizerConfig(
        window_seconds=args.window_seconds,
        reference_quantile=args.quantile,
        minimum_active_seconds=args.minimum_active_ms / 1000.0,
        minimum_burst_ms=args.minimum_burst_ms,
    )
    outputs = analyze_recording(
        args.recording,
        args.baseline_report,
        args.output_dir,
        config=config,
        output_step_ms=args.output_step_ms,
        chunk_seconds=args.chunk_seconds,
    )
    print(json.dumps(outputs, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
