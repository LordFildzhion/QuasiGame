#!/usr/bin/env python3
"""Streaming two-channel sEMG interpreter for Resonance/SPEED.

Input: a Resonance Float64 Channels stream containing left_p and right_p.
Output: two one-channel streams, left_strength and right_strength, in [0, 1].

The processing state (IIR filters, RMS window and smoothing) is retained between
blocks. Calibration is per arm and is loaded from a JSON file created by
calibrate_emg.py.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
from scipy import signal


@dataclass(frozen=True)
class FilterConfig:
    low_hz: float = 20.0
    high_hz: float = 200.0
    notch_hz: float | None = 50.0
    notch_q: float = 30.0
    order: int = 4
    rms_window_ms: float = 200.0
    attack_ms: float = 50.0
    release_ms: float = 150.0
    gap_reset_factor: float = 2.5

    def validate(self, sampling_rate: float) -> None:
        nyquist = sampling_rate / 2.0
        if not (0.0 < self.low_hz < self.high_hz < nyquist):
            raise ValueError(
                f"Полоса фильтра должна удовлетворять 0 < low < high < Nyquist "
                f"({nyquist:g} Гц); получено {self.low_hz:g}–{self.high_hz:g} Гц"
            )
        if self.notch_hz is not None and not (0.0 < self.notch_hz < nyquist):
            raise ValueError("Частота режекторного фильтра должна быть ниже Найквиста")
        if self.notch_q <= 0:
            raise ValueError("notch_q должен быть больше нуля")
        if self.order < 1:
            raise ValueError("Порядок Butterworth должен быть не меньше 1")
        if self.rms_window_ms <= 0 or self.attack_ms <= 0 or self.release_ms <= 0:
            raise ValueError("Окно RMS и времена сглаживания должны быть больше нуля")
        if self.gap_reset_factor <= 1:
            raise ValueError("gap_reset_factor должен быть больше 1")

    @classmethod
    def from_dict(cls, value: dict[str, Any] | None) -> "FilterConfig":
        return cls(**(value or {}))


@dataclass(frozen=True)
class EMGCalibration:
    schema_version: int
    sampling_rate_hz: float
    left_channel_index: int
    right_channel_index: int
    left_channel_name: str
    right_channel_name: str
    left_baseline_rms: float
    right_baseline_rms: float
    left_threshold_rms: float
    right_threshold_rms: float
    left_mvc_rms: float
    right_mvc_rms: float
    filter: FilterConfig
    calibration_method: str = "rest_q95_and_mvc_q95"

    def validate(self) -> None:
        if self.schema_version != 1:
            raise ValueError(f"Неподдерживаемая версия калибровки: {self.schema_version}")
        if self.sampling_rate_hz <= 0 or not math.isfinite(self.sampling_rate_hz):
            raise ValueError("Некорректная частота дискретизации в калибровке")
        if min(self.left_channel_index, self.right_channel_index) < 0:
            raise ValueError("Индексы каналов не могут быть отрицательными")
        for side in ("left", "right"):
            baseline = getattr(self, f"{side}_baseline_rms")
            threshold = getattr(self, f"{side}_threshold_rms")
            mvc = getattr(self, f"{side}_mvc_rms")
            if not all(math.isfinite(v) and v >= 0 for v in (baseline, threshold, mvc)):
                raise ValueError(f"Некорректные уровни калибровки для {side}")
            if mvc <= threshold:
                raise ValueError(
                    f"Для {side} MVC ({mvc:g}) должен быть выше порога "
                    f"активации ({threshold:g}); нужна повторная калибровка"
                )
        self.filter.validate(self.sampling_rate_hz)

    def to_dict(self) -> dict[str, Any]:
        value = asdict(self)
        value["filter"] = asdict(self.filter)
        return value

    @classmethod
    def from_dict(cls, value: dict[str, Any]) -> "EMGCalibration":
        payload = dict(value)
        payload["filter"] = FilterConfig.from_dict(payload.get("filter"))
        result = cls(**payload)
        result.validate()
        return result

    @classmethod
    def load(cls, path: str | Path) -> "EMGCalibration":
        with Path(path).expanduser().open("r", encoding="utf-8") as file:
            return cls.from_dict(json.load(file))

    def save(self, path: str | Path) -> None:
        self.validate()
        destination = Path(path).expanduser()
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("w", encoding="utf-8") as file:
            json.dump(self.to_dict(), file, ensure_ascii=False, indent=2)
            file.write("\n")


@dataclass
class EMGFrame:
    left_strength: np.ndarray
    right_strength: np.ndarray
    left_rms: np.ndarray
    right_rms: np.ndarray

    @property
    def strengths(self) -> np.ndarray:
        return np.column_stack((self.left_strength, self.right_strength))


class StreamingEMGFrontEnd:
    """Stateful filters + RMS envelope; safe to call with consecutive blocks."""

    def __init__(self, sampling_rate: float, config: FilterConfig | None = None):
        self.sampling_rate = float(sampling_rate)
        self.config = config or FilterConfig()
        self.config.validate(self.sampling_rate)

        bandpass = signal.butter(
            self.config.order,
            [self.config.low_hz, self.config.high_hz],
            btype="bandpass",
            fs=self.sampling_rate,
            output="sos",
        )
        sections = [bandpass]
        if self.config.notch_hz is not None:
            b, a = signal.iirnotch(
                self.config.notch_hz,
                self.config.notch_q,
                fs=self.sampling_rate,
            )
            sections.append(signal.tf2sos(b, a))
        self._sos = np.vstack(sections)

        self._window_samples = max(
            1, int(round(self.config.rms_window_ms * self.sampling_rate / 1000.0))
        )
        self._rms_b = np.full(self._window_samples, 1.0 / self._window_samples)
        self._attack_alpha = 1.0 - math.exp(
            -1.0 / (self.config.attack_ms * self.sampling_rate / 1000.0)
        )
        self._release_alpha = 1.0 - math.exp(
            -1.0 / (self.config.release_ms * self.sampling_rate / 1000.0)
        )
        self._gap_limit_ns = (
            self.config.gap_reset_factor * 1_000_000_000.0 / self.sampling_rate
        )
        self.reset()

    def reset(self) -> None:
        self._sos_zi: np.ndarray | None = None
        self._rms_zi: np.ndarray | None = None
        self._smoothed = np.zeros(2, dtype=np.float64)
        self._last_timestamp_ns: int | None = None

    def _reset_signal_state(self) -> None:
        self._sos_zi = None
        self._rms_zi = None
        self._smoothed[:] = 0.0

    def _process_contiguous(self, samples: np.ndarray) -> np.ndarray:
        if samples.shape[0] == 0:
            return np.empty((0, 2), dtype=np.float64)

        if self._sos_zi is None:
            steady = signal.sosfilt_zi(self._sos)
            self._sos_zi = steady[:, :, np.newaxis] * samples[0][np.newaxis, np.newaxis, :]

        filtered, self._sos_zi = signal.sosfilt(
            self._sos,
            samples,
            axis=0,
            zi=self._sos_zi,
        )

        squared = np.square(filtered)
        if self._window_samples > 1 and self._rms_zi is None:
            steady = signal.lfilter_zi(self._rms_b, [1.0])
            self._rms_zi = steady[:, np.newaxis] * squared[0][np.newaxis, :]

        if self._window_samples > 1:
            mean_square, self._rms_zi = signal.lfilter(
                self._rms_b,
                [1.0],
                squared,
                axis=0,
                zi=self._rms_zi,
            )
        else:
            mean_square = squared

        rms = np.sqrt(np.maximum(mean_square, 0.0))
        smoothed = np.empty_like(rms)
        previous = self._smoothed.copy()
        for index, current in enumerate(rms):
            alpha = np.where(current >= previous, self._attack_alpha, self._release_alpha)
            previous = previous + alpha * (current - previous)
            smoothed[index] = previous
        self._smoothed = previous
        return smoothed

    def process(
        self,
        samples: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> np.ndarray:
        """Return smoothed RMS [rows, 2], resetting across gaps and invalid rows."""
        values = np.asarray(samples, dtype=np.float64)
        if values.ndim != 2 or values.shape[1] != 2:
            raise ValueError(f"Ожидался массив [samples, 2], получено {values.shape}")
        if timestamps_ns is not None:
            timestamps = np.asarray(timestamps_ns, dtype=np.int64).reshape(-1)
            if timestamps.size != values.shape[0]:
                raise ValueError("Число временных меток не совпадает с числом отсчётов")
        else:
            timestamps = None

        output = np.zeros_like(values, dtype=np.float64)
        valid = np.isfinite(values).all(axis=1)
        index = 0
        while index < values.shape[0]:
            if not valid[index]:
                self._reset_signal_state()
                self._last_timestamp_ns = None
                index += 1
                continue

            if timestamps is not None and self._last_timestamp_ns is not None:
                delta = int(timestamps[index]) - self._last_timestamp_ns
                if delta <= 0 or delta > self._gap_limit_ns:
                    self._reset_signal_state()
                    self._last_timestamp_ns = None

            end = index + 1
            while end < values.shape[0] and valid[end]:
                if timestamps is not None:
                    delta = int(timestamps[end]) - int(timestamps[end - 1])
                    if delta <= 0 or delta > self._gap_limit_ns:
                        break
                end += 1

            output[index:end] = self._process_contiguous(values[index:end])
            if timestamps is not None:
                self._last_timestamp_ns = int(timestamps[end - 1])
            else:
                self._last_timestamp_ns = None
            index = end

        return output


class EMGInterpreter:
    """Turns a two-channel input matrix into calibrated left/right activity."""

    def __init__(self, calibration: EMGCalibration):
        calibration.validate()
        self.calibration = calibration
        self.front_end = StreamingEMGFrontEnd(
            calibration.sampling_rate_hz,
            calibration.filter,
        )
        self._indices = (calibration.left_channel_index, calibration.right_channel_index)
        self._thresholds = np.asarray(
            [calibration.left_threshold_rms, calibration.right_threshold_rms],
            dtype=np.float64,
        )
        self._mvc = np.asarray(
            [calibration.left_mvc_rms, calibration.right_mvc_rms],
            dtype=np.float64,
        )

    def process_block(
        self,
        data: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> EMGFrame:
        matrix = np.asarray(data, dtype=np.float64)
        if matrix.ndim != 2:
            raise ValueError(f"Ожидался двумерный входной блок, получено {matrix.shape}")
        if matrix.shape[1] <= max(self._indices):
            raise ValueError(
                f"Во входном потоке {matrix.shape[1]} каналов, но требуются индексы "
                f"{self._indices[0]} и {self._indices[1]}"
            )

        selected = matrix[:, self._indices]
        rms = self.front_end.process(selected, timestamps_ns)
        denominator = self._mvc - self._thresholds
        strength = np.clip((rms - self._thresholds) / denominator, 0.0, 1.0)
        strength[~np.isfinite(strength)] = 0.0

        return EMGFrame(
            left_strength=strength[:, 0],
            right_strength=strength[:, 1],
            left_rms=rms[:, 0],
            right_rms=rms[:, 1],
        )


def build_speed_pipeline(calibration_path: str | Path) -> None:
    """Declare two outputs in Resonance's SPEED Python engine.

    Put this function call in SPEED's ``Code`` field. Import paths belong in
    ``Load code``; the function is executed once while SPEED prepares its plan.
    """
    import resonance
    import resonance.db as db
    import resonance.si as si
    from resonance.internal import Processor

    calibration = EMGCalibration.load(calibration_path)

    class _EMGResonanceTransform(Processor):
        def __init__(self) -> None:
            self._interpreter: EMGInterpreter | None = None
            self._left_si = None
            self._right_si = None

        def prepare(self, channels: db.Channels):
            if not isinstance(channels, db.Channels):
                raise TypeError("EMGInterpreter ожидает поток Channels")
            sampling_rate = float(channels.SI.samplingRate)
            if not math.isclose(
                sampling_rate,
                calibration.sampling_rate_hz,
                rel_tol=0.0,
                abs_tol=0.01,
            ):
                raise ValueError(
                    f"Частота входа {sampling_rate:g} Гц не совпадает с MVC-калибровкой "
                    f"{calibration.sampling_rate_hz:g} Гц"
                )
            if channels.SI.channels <= max(
                calibration.left_channel_index,
                calibration.right_channel_index,
            ):
                raise ValueError(
                    f"В потоке {channels.SI.channels} каналов; калибровка ожидает индексы "
                    f"{calibration.left_channel_index}/{calibration.right_channel_index}"
                )

            self._interpreter = EMGInterpreter(calibration)
            self._left_si = si.Channels(channels=1, samplingRate=sampling_rate)
            self._right_si = si.Channels(channels=1, samplingRate=sampling_rate)
            return self._left_si, self._right_si

        def online(self, channels: db.Channels):
            if self._interpreter is None or self._left_si is None or self._right_si is None:
                raise RuntimeError("EMGInterpreter не был подготовлен")
            frame = self._interpreter.process_block(
                np.asarray(channels),
                channels.TS,
            )
            left = db.Channels(
                self._left_si,
                channels.TS,
                frame.left_strength.reshape(-1, 1),
            )
            right = db.Channels(
                self._right_si,
                channels.TS,
                frame.right_strength.reshape(-1, 1),
            )
            return left, right

    raw = resonance.input(0)
    transform = _EMGResonanceTransform()
    left_output, right_output = transform.call(raw)
    resonance.createOutput(left_output, "left_strength")
    resonance.createOutput(right_output, "right_strength")


# --- HDF5 calibration reader -------------------------------------------------


def _decode(value: Any) -> str:
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return str(value)


def load_hdf5_recording(
    path: str | Path,
    stream_name: str | None = None,
) -> tuple[np.ndarray, list[str | None], float, np.ndarray, str]:
    """Read either the early /eeg layout or the Resonance stream layout."""
    import h5py

    with h5py.File(path, "r") as root:
        candidates_by_name = {}
        if "eeg" in root and isinstance(root["eeg"], h5py.Group) and "data" in root["eeg"]:
            candidates_by_name["eeg"] = root["eeg"]
        for name, item in root.items():
            if isinstance(item, h5py.Group) and "data" in item and "streamInfo" in item:
                candidates_by_name[name] = item
        candidates = list(candidates_by_name.items())

        if stream_name is not None:
            candidates = [entry for entry in candidates if entry[0] == stream_name]
        if not candidates:
            raise ValueError("В HDF5 не найден числовой EEG-поток с dataset 'data'")
        if len(candidates) > 1:
            raise ValueError(
                "В HDF5 найдено несколько числовых потоков. Укажи нужный через --stream: "
                + ", ".join(name for name, _ in candidates)
            )

        selected_name, group = candidates[0]
        data = np.asarray(group["data"], dtype=np.float64)
        if data.ndim != 2:
            raise ValueError(f"Поток {selected_name!r}: ожидалась матрица [samples, channels]")

        sampling_rate = None
        labels: list[str | None] = []
        if "nominal_srate" in group.attrs:
            sampling_rate = float(group.attrs["nominal_srate"])
        if "channel_names" in group:
            labels = [_decode(value) for value in group["channel_names"][...]]

        if "streamInfo" in group:
            info = group["streamInfo"]
            if "samplingRate" in info:
                sampling_rate = float(np.asarray(info["samplingRate"])[0])
            if "temporary_as_json" in info:
                raw_json = info["temporary_as_json"][0]
                metadata = json.loads(_decode(raw_json))
                properties = metadata.get("metaData", {}).get("perChannelProperties", {})
                names = properties.get("name")
                if isinstance(names, list):
                    labels = [None if name is None else str(name) for name in names]

        if sampling_rate is None or sampling_rate <= 0:
            raise ValueError(f"Поток {selected_name!r}: не найдена частота дискретизации")
        if labels and len(labels) != data.shape[1]:
            labels = []

        if "time_stamps" in group:
            source_times = np.asarray(group["time_stamps"], dtype=np.float64).reshape(-1)
            if source_times.size != data.shape[0]:
                raise ValueError("time_stamps не совпадает с количеством строк data")
            relative_times = source_times - source_times[0]
            timestamps_ns = np.rint(relative_times * 1_000_000_000.0).astype(np.int64)
        elif "blocks" in group:
            blocks = group["blocks"]
            counts = np.asarray(blocks["samples"], dtype=np.uint64)
            total = int(counts.sum())
            if total != data.shape[0]:
                raise ValueError(
                    f"Индекс blocks покрывает {total} строк, а data содержит {data.shape[0]}"
                )
            reconstructed = np.empty(data.shape[0], dtype=np.int64)
            offset = 0
            period_ns = 1_000_000_000.0 / sampling_rate
            for block in blocks:
                count = int(block["samples"])
                created = int(block["created"])
                reconstructed[offset:offset + count] = np.rint(
                    created - np.arange(count - 1, -1, -1) * period_ns
                ).astype(np.int64)
                offset += count
            timestamps_ns = reconstructed - reconstructed[0]
        else:
            timestamps_ns = np.rint(
                np.arange(data.shape[0], dtype=np.float64) * 1_000_000_000.0 / sampling_rate
            ).astype(np.int64)

    if data.shape[0] < int(round(sampling_rate * 2.0)):
        raise ValueError("Запись слишком короткая для надёжной калибровки")
    return data, labels, sampling_rate, timestamps_ns, selected_name


def calibrate_from_recording(
    data: np.ndarray,
    labels: list[str | None],
    sampling_rate: float,
    timestamps_ns: np.ndarray,
    *,
    rest_interval: tuple[float, float],
    left_mvc_interval: tuple[float, float],
    right_mvc_interval: tuple[float, float],
    left_channel_index: int = 63,
    right_channel_index: int = 65,
    left_channel_name: str = "left_p",
    right_channel_name: str = "right_p",
    filter_config: FilterConfig | None = None,
    edge_trim_ms: float = 250.0,
) -> tuple[EMGCalibration, dict[str, float]]:
    config = filter_config or FilterConfig()
    config.validate(sampling_rate)
    if left_channel_index == right_channel_index:
        raise ValueError("Для левой и правой руки должны быть разные каналы")
    if max(left_channel_index, right_channel_index) >= data.shape[1]:
        raise ValueError(
            f"В записи {data.shape[1]} каналов, но заданы индексы "
            f"{left_channel_index}/{right_channel_index}"
        )
    if len(labels) == data.shape[1]:
        for index, expected, side in (
            (left_channel_index, left_channel_name, "левой"),
            (right_channel_index, right_channel_name, "правой"),
        ):
            actual = labels[index]
            if actual and actual != expected:
                raise ValueError(
                    f"На индексе {index} найден канал {actual!r}, а ожидался {expected!r} "
                    f"для {side} руки. Проверь channel index/name."
                )

    intervals = {
        "rest": rest_interval,
        "left_mvc": left_mvc_interval,
        "right_mvc": right_mvc_interval,
    }
    for name, (start, end) in intervals.items():
        if not (math.isfinite(start) and math.isfinite(end) and 0 <= start < end):
            raise ValueError(f"Некорректный интервал {name}: {start}:{end}")
        if end > timestamps_ns[-1] / 1e9 + 1.0 / sampling_rate:
            raise ValueError(f"Интервал {name} выходит за пределы записи")
    if max(rest_interval[0], left_mvc_interval[0]) < min(rest_interval[1], left_mvc_interval[1]):
        raise ValueError("Интервалы rest и left-mvc пересекаются")
    if max(rest_interval[0], right_mvc_interval[0]) < min(rest_interval[1], right_mvc_interval[1]):
        raise ValueError("Интервалы rest и right-mvc пересекаются")
    if max(left_mvc_interval[0], right_mvc_interval[0]) < min(left_mvc_interval[1], right_mvc_interval[1]):
        raise ValueError("Интервалы MVC левой и правой руки пересекаются")

    selected = np.asarray(data[:, [left_channel_index, right_channel_index]], dtype=np.float64)
    front_end = StreamingEMGFrontEnd(sampling_rate, config)
    rms = front_end.process(selected, timestamps_ns)
    relative_seconds = timestamps_ns.astype(np.float64) / 1e9

    trim_samples = int(round(edge_trim_ms * sampling_rate / 1000.0))

    def interval_values(interval: tuple[float, float], column: int) -> np.ndarray:
        start, end = interval
        # Convert relative recording time to sample indexes. Trim interval edges
        # to avoid filter/gesture onset transients influencing calibration.
        left = int(np.searchsorted(relative_seconds, start, side="left")) + trim_samples
        right = int(np.searchsorted(relative_seconds, end, side="right")) - trim_samples
        values = rms[max(0, left):min(len(rms), right), column]
        values = values[np.isfinite(values)]
        if values.size < int(0.5 * sampling_rate):
            raise ValueError(
                f"После удаления краевых {edge_trim_ms:g} мс в интервале "
                f"{start:g}:{end:g} осталось слишком мало данных"
            )
        return values

    def estimate(column: int, mvc_interval: tuple[float, float]) -> tuple[float, float, float, float]:
        rest = interval_values(rest_interval, column)
        mvc = interval_values(mvc_interval, column)
        baseline = float(np.median(rest))
        mad = float(np.median(np.abs(rest - baseline)))
        robust_sigma = 1.4826 * mad
        threshold = max(float(np.percentile(rest, 95.0)), baseline + 4.0 * robust_sigma)
        mvc_level = float(np.percentile(mvc, 95.0))
        if mvc_level <= threshold * 1.15 or mvc_level - threshold < 1e-9:
            raise ValueError(
                "MVC недостаточно отличается от покоя: "
                f"MVC={mvc_level:.6g}, порог={threshold:.6g}. "
                "Проверь интервалы, контакт электродов и повтори MVC."
            )
        return baseline, threshold, mvc_level, float(np.percentile(rest, 95.0))

    left_base, left_threshold, left_mvc, left_rest_q95 = estimate(0, left_mvc_interval)
    right_base, right_threshold, right_mvc, right_rest_q95 = estimate(1, right_mvc_interval)

    calibration = EMGCalibration(
        schema_version=1,
        sampling_rate_hz=float(sampling_rate),
        left_channel_index=int(left_channel_index),
        right_channel_index=int(right_channel_index),
        left_channel_name=left_channel_name,
        right_channel_name=right_channel_name,
        left_baseline_rms=left_base,
        right_baseline_rms=right_base,
        left_threshold_rms=left_threshold,
        right_threshold_rms=right_threshold,
        left_mvc_rms=left_mvc,
        right_mvc_rms=right_mvc,
        filter=config,
    )
    calibration.validate()
    diagnostics = {
        "left_rest_q95": left_rest_q95,
        "right_rest_q95": right_rest_q95,
        "left_dynamic_range": left_mvc - left_threshold,
        "right_dynamic_range": right_mvc - right_threshold,
    }
    return calibration, diagnostics


def _parse_interval(value: str) -> tuple[float, float]:
    try:
        start_text, end_text = value.split(":", 1)
        return float(start_text), float(end_text)
    except (ValueError, TypeError) as exc:
        raise argparse.ArgumentTypeError("Интервал задаётся как START:END в секундах") from exc


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Потоковый интерпретатор sEMG и генератор MVC-калибровки"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    calibration_parser = subparsers.add_parser(
        "calibrate", help="Создать MVC-калибровку из HDF5-записи"
    )
    calibration_parser.add_argument("recording", help="Входной HDF5-файл")
    calibration_parser.add_argument("output", help="Путь для JSON-калибровки")
    calibration_parser.add_argument("--stream", default=None, help="Имя числового потока в HDF5")
    calibration_parser.add_argument("--rest", required=True, type=_parse_interval, help="Интервал покоя, например 0:5")
    calibration_parser.add_argument("--left-mvc", required=True, type=_parse_interval, help="Интервал MVC левой руки")
    calibration_parser.add_argument("--right-mvc", required=True, type=_parse_interval, help="Интервал MVC правой руки")
    calibration_parser.add_argument("--left-index", type=int, default=63)
    calibration_parser.add_argument("--right-index", type=int, default=65)
    calibration_parser.add_argument("--left-name", default="left_p")
    calibration_parser.add_argument("--right-name", default="right_p")
    calibration_parser.add_argument("--low", type=float, default=20.0, help="Нижняя граница полосы, Гц")
    calibration_parser.add_argument("--high", type=float, default=200.0, help="Верхняя граница полосы, Гц")
    calibration_parser.add_argument("--notch", type=float, default=50.0, help="Частота режекции; 0 отключает notch")
    calibration_parser.add_argument("--notch-q", type=float, default=30.0)
    calibration_parser.add_argument("--window-ms", type=float, default=200.0)
    calibration_parser.add_argument("--attack-ms", type=float, default=50.0)
    calibration_parser.add_argument("--release-ms", type=float, default=150.0)
    calibration_parser.add_argument("--edge-trim-ms", type=float, default=250.0)

    args = parser.parse_args()
    if args.command == "calibrate":
        data, labels, fs, timestamps, stream = load_hdf5_recording(args.recording, args.stream)
        if labels:
            print(f"Поток: {stream}; частота: {fs:g} Гц; форма: {data.shape}")
            print(f"Канал {args.left_index}: {labels[args.left_index]!r}")
            print(f"Канал {args.right_index}: {labels[args.right_index]!r}")
        config = FilterConfig(
            low_hz=args.low,
            high_hz=args.high,
            notch_hz=None if args.notch == 0 else args.notch,
            notch_q=args.notch_q,
            rms_window_ms=args.window_ms,
            attack_ms=args.attack_ms,
            release_ms=args.release_ms,
        )
        calibration, diagnostics = calibrate_from_recording(
            data,
            labels,
            fs,
            timestamps,
            rest_interval=args.rest,
            left_mvc_interval=args.left_mvc,
            right_mvc_interval=args.right_mvc,
            left_channel_index=args.left_index,
            right_channel_index=args.right_index,
            left_channel_name=args.left_name,
            right_channel_name=args.right_name,
            filter_config=config,
            edge_trim_ms=args.edge_trim_ms,
        )
        calibration.save(args.output)
        print(f"\nMVC-калибровка сохранена: {Path(args.output)}")
        print(f"Левая: baseline={calibration.left_baseline_rms:.6g}, "
              f"threshold={calibration.left_threshold_rms:.6g}, "
              f"MVC={calibration.left_mvc_rms:.6g}")
        print(f"Правая: baseline={calibration.right_baseline_rms:.6g}, "
              f"threshold={calibration.right_threshold_rms:.6g}, "
              f"MVC={calibration.right_mvc_rms:.6g}")
        print(f"Динамический диапазон: {diagnostics['left_dynamic_range']:.6g} / "
              f"{diagnostics['right_dynamic_range']:.6g}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
