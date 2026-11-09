#!/usr/bin/env python3
"""Adaptive sEMG mains cancellation and raw/residual signal quality monitoring.

The adaptive canceller estimates a narrowband line frequency from a rolling
window and uses two phase-continuous sinusoidal references with NLMS/LMS-style
coefficient adaptation. It is deliberately conservative: it only adapts when
there is measurable narrowband energy near the configured mains frequency.

The monitor reports raw and residual line contamination separately. All scores
are engineering diagnostics, not clinical metrics or proof of physiological
validity.
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
import math
from typing import Any

import numpy as np
from scipy import signal

from emg_interpreter import FilterConfig, StreamingEMGFrontEnd


@dataclass(frozen=True)
class MainsCancellerConfig:
    nominal_frequency_hz: float = 50.0
    search_low_hz: float = 48.0
    search_high_hz: float = 52.0
    window_seconds: float = 2.0
    update_interval_ms: float = 250.0
    narrowband_half_width_hz: float = 0.30
    minimum_narrowband_fraction: float = 0.08
    adaptation_rate: float = 0.02
    coefficient_release_seconds: float = 0.50
    frequency_smoothing: float = 0.20
    max_frequency_slew_hz: float = 0.25
    gap_reset_factor: float = 2.5

    def validate(self, sampling_rate_hz: float) -> None:
        nyquist = sampling_rate_hz / 2.0
        if not math.isfinite(sampling_rate_hz) or sampling_rate_hz <= 0:
            raise ValueError("sampling_rate_hz должен быть положительным")
        if not (0 < self.search_low_hz < self.nominal_frequency_hz < self.search_high_hz < nyquist):
            raise ValueError("Диапазон поиска сетевой частоты некорректен")
        if self.window_seconds < 1.0:
            raise ValueError("Окно оценки частоты должно быть не меньше 1 секунды")
        if self.update_interval_ms <= 0:
            raise ValueError("update_interval_ms должен быть положительным")
        if not 0 < self.narrowband_half_width_hz < 1.0:
            raise ValueError("narrowband_half_width_hz должен быть в (0, 1)")
        if not 0 < self.minimum_narrowband_fraction < 1:
            raise ValueError("minimum_narrowband_fraction должен быть в (0, 1)")
        if not 0 < self.adaptation_rate <= 0.25:
            raise ValueError("adaptation_rate должен быть в (0, 0.25]")
        if self.coefficient_release_seconds <= 0:
            raise ValueError("coefficient_release_seconds должен быть положительным")
        if not 0 < self.frequency_smoothing <= 1:
            raise ValueError("frequency_smoothing должен быть в (0, 1]")
        if self.max_frequency_slew_hz <= 0:
            raise ValueError("max_frequency_slew_hz должен быть положительным")
        if self.gap_reset_factor <= 1:
            raise ValueError("gap_reset_factor должен быть больше 1")


@dataclass
class MainsCancellationFrame:
    samples: np.ndarray
    estimated_frequency_hz: np.ndarray
    narrowband_fraction: np.ndarray
    enabled: np.ndarray


class AdaptiveMainsCanceller:
    """Stateful two-channel adaptive sinusoid canceller.

    Frequency is estimated from a rolling Hann-windowed spectrum. Each channel
    has independent sine/cosine coefficients, while the estimated line
    frequency is shared. Coefficients are adapted sample-by-sample to preserve
    phase continuity across arbitrary input block boundaries.
    """

    def __init__(
        self,
        sampling_rate_hz: float,
        config: MainsCancellerConfig | None = None,
    ) -> None:
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.config = config or MainsCancellerConfig()
        self.config.validate(self.sampling_rate_hz)
        self._window_samples = max(2, int(round(self.config.window_seconds * self.sampling_rate_hz)))
        self._update_samples = max(1, int(round(self.config.update_interval_ms * self.sampling_rate_hz / 1000.0)))
        self._gap_limit_ns = self.config.gap_reset_factor * 1e9 / self.sampling_rate_hz
        self._release = math.exp(-1.0 / (self.config.coefficient_release_seconds * self.sampling_rate_hz))
        self._nfft = max(32768, 2 ** int(math.ceil(math.log2(self._window_samples * 16))))
        self._window = signal.windows.hann(self._window_samples, sym=False)
        self.reset()

    def reset(self) -> None:
        self._ring = np.zeros((self._window_samples, 2), dtype=np.float64)
        self._write_index = 0
        self._count = 0
        self._samples_since_update = 0
        self._weights = np.zeros((2, 2), dtype=np.float64)  # [sin/cos, channel]
        self._phase = 0.0
        self._frequency_hz = float(self.config.nominal_frequency_hz)
        self._narrowband_fraction = 0.0
        self._enabled = False
        self._last_timestamp_ns: int | None = None

    def _reset_after_gap(self) -> None:
        self._ring.fill(0.0)
        self._write_index = 0
        self._count = 0
        self._samples_since_update = 0
        self._weights.fill(0.0)
        self._phase = 0.0
        self._frequency_hz = float(self.config.nominal_frequency_hz)
        self._narrowband_fraction = 0.0
        self._enabled = False

    def _ordered_window(self) -> np.ndarray:
        if self._count < self._window_samples:
            return self._ring[:self._count]
        if self._write_index == 0:
            return self._ring
        return np.concatenate((self._ring[self._write_index:], self._ring[:self._write_index]), axis=0)

    def _estimate_line(self) -> tuple[float, float]:
        values = self._ordered_window()
        if values.shape[0] < self._window_samples:
            return self._frequency_hz, 0.0

        centered = values - np.mean(values, axis=0, keepdims=True)
        windowed = centered * self._window[:, None]
        spectrum = np.abs(np.fft.rfft(windowed, n=self._nfft, axis=0)) ** 2
        frequencies = np.fft.rfftfreq(self._nfft, d=1.0 / self.sampling_rate_hz)
        band = (frequencies >= 20.0) & (frequencies <= min(200.0, self.sampling_rate_hz / 2.0 - 1.0))
        search = (frequencies >= self.config.search_low_hz) & (frequencies <= self.config.search_high_hz)
        if not np.any(band) or not np.any(search):
            return self._frequency_hz, 0.0

        # Normalize each channel before combining so the noisier electrode
        # cannot completely dominate the shared frequency estimate.
        band_power = np.sum(spectrum[band], axis=0)
        normalized = spectrum / np.maximum(band_power[None, :], np.finfo(float).tiny)
        combined = np.mean(normalized, axis=1)
        search_indices = np.flatnonzero(search)
        peak_index = int(search_indices[np.argmax(combined[search])])

        # Parabolic interpolation in log-power gives sub-bin frequency accuracy.
        if 0 < peak_index < combined.size - 1:
            left, center, right = np.log(combined[peak_index - 1:peak_index + 2] + 1e-30)
            denominator = left - 2.0 * center + right
            offset = 0.5 * (left - right) / denominator if abs(denominator) > 1e-15 else 0.0
            offset = float(np.clip(offset, -1.0, 1.0))
        else:
            offset = 0.0
        candidate = float((peak_index + offset) * self.sampling_rate_hz / self._nfft)

        narrow = np.abs(frequencies - candidate) <= self.config.narrowband_half_width_hz
        total_power = float(np.sum(combined[band]))
        narrow_power = float(np.sum(combined[narrow]))
        fraction = float(np.clip(narrow_power / max(total_power, np.finfo(float).tiny), 0.0, 1.0))
        return candidate, fraction

    def process(
        self,
        samples: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> MainsCancellationFrame:
        values = np.asarray(samples, dtype=np.float64)
        if values.ndim != 2 or values.shape[1] != 2:
            raise ValueError(f"Ожидался массив [samples, 2], получено {values.shape}")
        if timestamps_ns is None:
            timestamps = None
        else:
            timestamps = np.asarray(timestamps_ns, dtype=np.int64).reshape(-1)
            if timestamps.size != values.shape[0]:
                raise ValueError("Число временных меток не совпадает с числом отсчётов")

        cleaned = np.zeros_like(values)
        frequencies = np.full(values.shape[0], self._frequency_hz, dtype=np.float64)
        fractions = np.zeros(values.shape[0], dtype=np.float64)
        enabled = np.zeros(values.shape[0], dtype=bool)

        for index, row in enumerate(values):
            finite = np.isfinite(row).all()
            if not finite:
                self._reset_after_gap()
                self._last_timestamp_ns = None
                cleaned[index] = np.nan
                continue

            if timestamps is not None and self._last_timestamp_ns is not None:
                delta = int(timestamps[index]) - self._last_timestamp_ns
                if delta <= 0 or delta > self._gap_limit_ns:
                    self._reset_after_gap()
                    self._last_timestamp_ns = None

            self._ring[self._write_index] = row
            self._write_index = (self._write_index + 1) % self._window_samples
            self._count = min(self._count + 1, self._window_samples)
            self._samples_since_update += 1

            if self._count >= self._window_samples and self._samples_since_update >= self._update_samples:
                self._samples_since_update = 0
                candidate, fraction = self._estimate_line()
                self._narrowband_fraction = fraction
                if fraction >= self.config.minimum_narrowband_fraction:
                    max_step = self.config.max_frequency_slew_hz
                    delta_f = float(np.clip(candidate - self._frequency_hz, -max_step, max_step))
                    target = self._frequency_hz + delta_f
                    alpha = self.config.frequency_smoothing
                    self._frequency_hz += alpha * (target - self._frequency_hz)
                    self._enabled = True
                else:
                    self._enabled = False

            phase_step = 2.0 * math.pi * self._frequency_hz / self.sampling_rate_hz
            self._phase = (self._phase + phase_step) % (2.0 * math.pi)
            reference = np.asarray((math.sin(self._phase), math.cos(self._phase)), dtype=np.float64)

            if self._enabled:
                predicted = reference @ self._weights
                residual = row - predicted
                self._weights += (2.0 * self.config.adaptation_rate) * np.outer(reference, residual)
                cleaned[index] = residual
            else:
                self._weights *= self._release
                cleaned[index] = row

            frequencies[index] = self._frequency_hz
            fractions[index] = self._narrowband_fraction
            enabled[index] = self._enabled
            if timestamps is not None:
                self._last_timestamp_ns = int(timestamps[index])

        return MainsCancellationFrame(cleaned, frequencies, fractions, enabled)


@dataclass(frozen=True)
class SignalQualityConfig:
    window_seconds: float = 2.0
    update_interval_ms: float = 250.0
    mains_low_hz: float = 45.0
    mains_high_hz: float = 55.0
    signal_low_hz: float = 20.0
    signal_high_hz: float = 200.0
    minimum_finite_fraction: float = 0.999
    maximum_mains_fraction: float = 0.65
    maximum_flatline_fraction: float = 0.90
    maximum_clipping_fraction: float = 0.005
    maximum_impulse_fraction: float = 0.02
    minimum_quality: float = 0.50
    gap_reset_factor: float = 2.5

    def validate(self, sampling_rate_hz: float) -> None:
        nyquist = sampling_rate_hz / 2.0
        if not math.isfinite(sampling_rate_hz) or sampling_rate_hz <= 0:
            raise ValueError("sampling_rate_hz должен быть положительным")
        if self.window_seconds < 1.0:
            raise ValueError("window_seconds должен быть не меньше 1 секунды")
        if self.update_interval_ms <= 0:
            raise ValueError("update_interval_ms должен быть положительным")
        if not (0 < self.mains_low_hz < self.mains_high_hz < nyquist):
            raise ValueError("Полоса сетевой помехи должна находиться ниже Найквиста")
        if not (0 < self.signal_low_hz < self.signal_high_hz < nyquist):
            raise ValueError("Полоса контроля сигнала должна находиться ниже Найквиста")
        for name in (
            "minimum_finite_fraction", "maximum_mains_fraction",
            "maximum_flatline_fraction", "maximum_clipping_fraction",
            "maximum_impulse_fraction", "minimum_quality",
        ):
            value = getattr(self, name)
            if not 0 <= value <= 1:
                raise ValueError(f"{name} должен находиться в [0, 1]")
        if self.gap_reset_factor <= 1:
            raise ValueError("gap_reset_factor должен быть больше 1")


@dataclass(frozen=True)
class ChannelQualityMetrics:
    finite_fraction: float = 0.0
    mains_fraction: float = 1.0  # Backward-compatible alias for residual_mains_fraction.
    raw_mains_fraction: float = 1.0
    residual_mains_fraction: float = 1.0
    mains_attenuation_db: float = 0.0
    flatline_fraction: float = 1.0
    clipping_fraction: float = 1.0
    impulse_fraction: float = 1.0
    quality_score: float = 0.0
    ready: bool = False
    artifact_free: bool = False
    warnings: tuple[str, ...] = ("Ожидание окна диагностики",)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class SignalQualityFrame:
    quality: np.ndarray
    ready: np.ndarray
    artifact_free: np.ndarray
    raw_mains_fraction: np.ndarray
    residual_mains_fraction: np.ndarray
    mains_attenuation_db: np.ndarray


class NoiseSuppressor:
    """Adaptive mains cancellation, Butterworth band-pass, optional IIR notch and RMS."""

    def __init__(
        self,
        sampling_rate_hz: float,
        config: FilterConfig | None = None,
        mains_config: MainsCancellerConfig | None = None,
    ) -> None:
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.config = config or FilterConfig()
        self.canceller = AdaptiveMainsCanceller(self.sampling_rate_hz, mains_config)
        self._frontend = StreamingEMGFrontEnd(self.sampling_rate_hz, self.config)
        self.last_cancelled_samples = np.empty((0, 2), dtype=np.float64)
        self.last_cancellation_frame = MainsCancellationFrame(
            np.empty((0, 2)), np.empty(0), np.empty(0), np.empty(0, dtype=bool)
        )

    def reset(self) -> None:
        self.canceller.reset()
        self._frontend.reset()
        self.last_cancelled_samples = np.empty((0, 2), dtype=np.float64)
        self.last_cancellation_frame = MainsCancellationFrame(
            np.empty((0, 2)), np.empty(0), np.empty(0), np.empty(0, dtype=bool)
        )

    def process(
        self,
        samples: np.ndarray,
        timestamps_ns: np.ndarray | None = None,
    ) -> np.ndarray:
        cancellation = self.canceller.process(samples, timestamps_ns)
        self.last_cancellation_frame = cancellation
        self.last_cancelled_samples = cancellation.samples
        return self._frontend.process(cancellation.samples, timestamps_ns)


class SignalQualityMonitor:
    """Rolling quality monitor distinguishing input and residual mains energy."""

    def __init__(
        self,
        sampling_rate_hz: float,
        config: SignalQualityConfig | None = None,
    ) -> None:
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.config = config or SignalQualityConfig()
        self.config.validate(self.sampling_rate_hz)
        self._window_samples = max(2, int(round(self.config.window_seconds * self.sampling_rate_hz)))
        self._update_samples = max(1, int(round(self.config.update_interval_ms * self.sampling_rate_hz / 1000.0)))
        self._gap_limit_ns = self.config.gap_reset_factor * 1e9 / self.sampling_rate_hz
        self.reset()

    @property
    def metrics(self) -> tuple[ChannelQualityMetrics, ChannelQualityMetrics]:
        return self._metrics[0], self._metrics[1]

    def reset(self) -> None:
        self._raw_ring = np.zeros((self._window_samples, 2), dtype=np.float64)
        self._residual_ring = np.zeros((self._window_samples, 2), dtype=np.float64)
        self._valid_ring = np.zeros((self._window_samples, 2), dtype=bool)
        self._write_index = 0
        self._count = 0
        self._samples_since_update = 0
        self._last_timestamp_ns: int | None = None
        self._metrics = [ChannelQualityMetrics(), ChannelQualityMetrics()]

    def _ordered_window(self) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        if self._count < self._window_samples:
            return self._raw_ring[:self._count], self._residual_ring[:self._count], self._valid_ring[:self._count]
        order = np.concatenate((np.arange(self._write_index, self._window_samples), np.arange(0, self._write_index)))
        return self._raw_ring[order], self._residual_ring[order], self._valid_ring[order]

    @staticmethod
    def _fraction_in_runs(mask: np.ndarray, minimum_run: int) -> float:
        if mask.size == 0:
            return 1.0
        padded = np.concatenate(([False], mask.astype(bool), [False]))
        changes = np.diff(padded.astype(np.int8))
        starts = np.flatnonzero(changes == 1)
        ends = np.flatnonzero(changes == -1)
        selected = np.zeros(mask.size, dtype=bool)
        for start, end in zip(starts, ends):
            if end - start >= minimum_run:
                selected[start:end] = True
        return float(np.mean(selected))

    def _mains_fraction(self, values: np.ndarray) -> float:
        if values.size < max(int(self.sampling_rate_hz), 128):
            return 1.0
        nperseg = min(values.size, max(int(self.sampling_rate_hz), int(round(self.sampling_rate_hz * 2.0))))
        frequencies, power = signal.welch(
            values, fs=self.sampling_rate_hz, nperseg=nperseg,
            detrend="constant", scaling="density",
        )
        band = (frequencies >= self.config.signal_low_hz) & (frequencies <= self.config.signal_high_hz)
        mains = (frequencies >= self.config.mains_low_hz) & (frequencies <= self.config.mains_high_hz)
        if np.count_nonzero(band) < 2 or np.count_nonzero(mains) < 2:
            return 1.0
        total = float(np.trapz(power[band], frequencies[band]))
        line = float(np.trapz(power[mains], frequencies[mains]))
        return float(np.clip(line / max(total, np.finfo(float).tiny), 0.0, 1.0))

    def _evaluate_channel(
        self,
        raw_values: np.ndarray,
        residual_values: np.ndarray,
        valid: np.ndarray,
    ) -> ChannelQualityMetrics:
        finite_fraction = float(np.mean(valid)) if valid.size else 0.0
        raw = raw_values[valid]
        residual = residual_values[valid]
        minimum_n = max(int(self.sampling_rate_hz), 128)
        if raw.size < minimum_n:
            return ChannelQualityMetrics(
                finite_fraction=finite_fraction,
                warnings=("Недостаточно данных для спектральной оценки",),
            )

        centered = raw - float(np.median(raw))
        amplitude = float(np.max(np.abs(centered))) if centered.size else 0.0
        robust_sigma = 1.4826 * float(np.median(np.abs(centered - np.median(centered))))
        tolerance = max(robust_sigma * 1e-6, amplitude * 1e-10, np.finfo(np.float64).eps)

        differences = np.diff(raw)
        flatline_fraction = float(np.mean(np.abs(differences) <= tolerance)) if differences.size else 1.0
        min_value, max_value = float(np.min(raw)), float(np.max(raw))
        at_extreme = (np.abs(raw - min_value) <= tolerance) | (np.abs(raw - max_value) <= tolerance)
        clipping_fraction = self._fraction_in_runs(at_extreme, minimum_run=3)

        second_difference = np.diff(raw, n=2)
        if second_difference.size:
            center_d2 = float(np.median(second_difference))
            abs_dev = np.abs(second_difference - center_d2)
            mad_d2 = 1.4826 * float(np.median(abs_dev))
            scale_floor = max(robust_sigma * 1e-3, tolerance)
            impulse_fraction = float(np.mean(abs_dev > 12.0 * max(mad_d2, scale_floor)))
        else:
            impulse_fraction = 1.0

        raw_mains = self._mains_fraction(raw)
        residual_mains = self._mains_fraction(residual)
        attenuation_db = float(10.0 * math.log10(
            max(raw_mains, 1e-12) / max(residual_mains, 1e-12)
        ))

        finite_score = float(np.clip(finite_fraction / self.config.minimum_finite_fraction, 0.0, 1.0))
        mains_score = 1.0 - float(np.clip(
            (residual_mains - 0.10) / max(self.config.maximum_mains_fraction - 0.10, 1e-9), 0.0, 1.0
        ))
        flatline_score = 1.0 - float(np.clip(flatline_fraction / max(self.config.maximum_flatline_fraction, 1e-9), 0.0, 1.0))
        clipping_score = 1.0 - float(np.clip(clipping_fraction / max(self.config.maximum_clipping_fraction, 1e-9), 0.0, 1.0))
        impulse_score = 1.0 - float(np.clip(impulse_fraction / max(self.config.maximum_impulse_fraction, 1e-9), 0.0, 1.0))
        score = float(np.clip(
            0.15 * finite_score + 0.55 * mains_score + 0.10 * flatline_score
            + 0.10 * clipping_score + 0.10 * impulse_score,
            0.0, 1.0,
        ))

        artifact_free = (
            finite_fraction >= self.config.minimum_finite_fraction
            and flatline_fraction < self.config.maximum_flatline_fraction
            and clipping_fraction <= self.config.maximum_clipping_fraction
            and impulse_fraction <= self.config.maximum_impulse_fraction
            and residual_mains <= self.config.maximum_mains_fraction
            and score >= self.config.minimum_quality
        )
        warnings: list[str] = []
        if finite_fraction < self.config.minimum_finite_fraction:
            warnings.append("Присутствуют NaN/Inf или пропущенные отсчёты")
        if raw_mains > self.config.maximum_mains_fraction:
            warnings.append("На входе присутствует сильная помеха вблизи частоты электросети")
        if residual_mains > self.config.maximum_mains_fraction:
            warnings.append("После подавления остаётся сильная помеха вблизи частоты электросети")
        elif raw_mains > self.config.maximum_mains_fraction:
            warnings.append("Адаптивное подавление уменьшило сетевую составляющую")
        if flatline_fraction >= self.config.maximum_flatline_fraction:
            warnings.append("Возможное залипание или отсутствие изменений сигнала")
        if clipping_fraction > self.config.maximum_clipping_fraction:
            warnings.append("Обнаружено возможное насыщение входного сигнала")
        if impulse_fraction > self.config.maximum_impulse_fraction:
            warnings.append("Повышенная доля резких импульсных артефактов")
        if score < self.config.minimum_quality:
            warnings.append("Общая оценка качества ниже заданного порога")
        if not warnings:
            warnings.append("Явных проблем качества в текущем окне не обнаружено")

        return ChannelQualityMetrics(
            finite_fraction=finite_fraction,
            mains_fraction=residual_mains,
            raw_mains_fraction=raw_mains,
            residual_mains_fraction=residual_mains,
            mains_attenuation_db=attenuation_db,
            flatline_fraction=flatline_fraction,
            clipping_fraction=clipping_fraction,
            impulse_fraction=impulse_fraction,
            quality_score=score,
            ready=True,
            artifact_free=artifact_free,
            warnings=tuple(warnings),
        )

    def process(
        self,
        samples: np.ndarray,
        residual_samples: np.ndarray | None = None,
        timestamps_ns: np.ndarray | None = None,
    ) -> SignalQualityFrame:
        raw = np.asarray(samples, dtype=np.float64)
        residual = raw if residual_samples is None else np.asarray(residual_samples, dtype=np.float64)
        if raw.ndim != 2 or raw.shape[1] != 2 or residual.shape != raw.shape:
            raise ValueError("samples и residual_samples должны иметь форму [samples, 2]")
        if timestamps_ns is None:
            timestamps = None
        else:
            timestamps = np.asarray(timestamps_ns, dtype=np.int64).reshape(-1)
            if timestamps.size != raw.shape[0]:
                raise ValueError("Количество timestamp не совпадает с числом отсчётов")

        quality = np.zeros((raw.shape[0], 2), dtype=np.float64)
        ready = np.zeros((raw.shape[0], 2), dtype=bool)
        artifact_free = np.zeros((raw.shape[0], 2), dtype=bool)
        raw_fraction = np.ones((raw.shape[0], 2), dtype=np.float64)
        residual_fraction = np.ones((raw.shape[0], 2), dtype=np.float64)
        attenuation = np.zeros((raw.shape[0], 2), dtype=np.float64)

        for row in range(raw.shape[0]):
            if timestamps is not None and self._last_timestamp_ns is not None:
                delta = int(timestamps[row]) - self._last_timestamp_ns
                if delta <= 0 or delta > self._gap_limit_ns:
                    self.reset()

            finite = np.isfinite(raw[row]) & np.isfinite(residual[row])
            self._raw_ring[self._write_index] = np.where(finite, raw[row], 0.0)
            self._residual_ring[self._write_index] = np.where(finite, residual[row], 0.0)
            self._valid_ring[self._write_index] = finite
            self._write_index = (self._write_index + 1) % self._window_samples
            self._count = min(self._count + 1, self._window_samples)
            self._samples_since_update += 1

            if self._count >= self._window_samples and self._samples_since_update >= self._update_samples:
                raw_window, residual_window, valid_window = self._ordered_window()
                self._metrics = [
                    self._evaluate_channel(raw_window[:, channel], residual_window[:, channel], valid_window[:, channel])
                    for channel in range(2)
                ]
                self._samples_since_update = 0

            for channel, metric in enumerate(self._metrics):
                quality[row, channel] = metric.quality_score
                ready[row, channel] = metric.ready
                artifact_free[row, channel] = metric.artifact_free
                raw_fraction[row, channel] = metric.raw_mains_fraction
                residual_fraction[row, channel] = metric.residual_mains_fraction
                attenuation[row, channel] = metric.mains_attenuation_db

            if timestamps is not None:
                self._last_timestamp_ns = int(timestamps[row])

        return SignalQualityFrame(quality, ready, artifact_free, raw_fraction, residual_fraction, attenuation)
