"""Noise-adaptive, event-based detector for brief sEMG contractions.

The detector estimates each channel's quiet envelope during an initial relaxed
calibration interval, then uses an onset/release hysteresis with a short
persistence check. One continuous contraction produces exactly one event.

This is an engineering detector, not a clinical or physiological classifier.
Its sensitivity must be checked against real rest and micro-contraction data.
"""
from __future__ import annotations

from dataclasses import dataclass
import math
from typing import Iterable

import numpy as np


@dataclass(frozen=True)
class ContractionDetectorSettings:
    calibration_seconds: float = 2.0
    onset_sigma: float = 4.0
    release_sigma: float = 1.5
    min_contraction_ms: float = 20.0
    release_ms: float = 28.0
    refractory_ms: float = 65.0
    full_scale_sigma: float = 14.0
    baseline_tracking_seconds: float = 12.0
    minimum_noise_floor: float = 1e-12

    def validate(self, sampling_rate_hz: float) -> None:
        if not math.isfinite(sampling_rate_hz) or sampling_rate_hz <= 0:
            raise ValueError("sampling_rate_hz must be positive")
        numeric = (self.calibration_seconds, self.onset_sigma, self.release_sigma,
                   self.min_contraction_ms, self.release_ms, self.refractory_ms,
                   self.full_scale_sigma, self.baseline_tracking_seconds,
                   self.minimum_noise_floor)
        if not all(math.isfinite(float(value)) for value in numeric):
            raise ValueError("event detector settings must be finite")
        if self.calibration_seconds <= 0:
            raise ValueError("calibration_seconds must be positive")
        if not 1.0 <= self.onset_sigma <= 10.0:
            raise ValueError("onset_sigma must be in [1, 10]")
        if not 0.2 <= self.release_sigma < self.onset_sigma:
            raise ValueError("release_sigma must be positive and below onset_sigma")
        for key in ("min_contraction_ms", "release_ms", "refractory_ms"):
            if getattr(self, key) < 0:
                raise ValueError(f"{key} cannot be negative")
        if self.full_scale_sigma <= self.onset_sigma:
            raise ValueError("full_scale_sigma must exceed onset_sigma")
        if self.baseline_tracking_seconds <= 0 or self.minimum_noise_floor <= 0:
            raise ValueError("baseline tracking and noise floor must be positive")


@dataclass(frozen=True)
class ContractionEvent:
    arm: str
    strength: float
    sample_index: int
    timestamp_ns: int | None
    peak_rms: float
    baseline_rms: float
    noise_sigma: float


@dataclass
class _ChannelState:
    calibration: list[float]
    ready: bool = False
    baseline: float = 0.0
    sigma: float = 0.0
    candidate_samples: int = 0
    in_event: bool = False
    release_samples: int = 0
    refractory_samples: int = 0
    peak: float = 0.0
    event_baseline: float = 0.0
    event_sigma: float = 0.0


class ContractionEventDetector:
    """Detect one event per contraction on two RMS-envelope channels."""

    ARMS = ("left", "right")

    def __init__(
        self,
        sampling_rate_hz: float,
        settings: ContractionDetectorSettings | None = None,
        enabled: tuple[bool, bool] = (True, True),
    ) -> None:
        self.sampling_rate_hz = float(sampling_rate_hz)
        self.settings = settings or ContractionDetectorSettings()
        self.settings.validate(self.sampling_rate_hz)
        self.enabled = tuple(bool(x) for x in enabled)
        self._calibration_samples = max(1, int(round(self.sampling_rate_hz * self.settings.calibration_seconds)))
        self._min_samples = max(1, int(math.ceil(self.sampling_rate_hz * self.settings.min_contraction_ms / 1000.0)))
        self._release_samples = max(1, int(math.ceil(self.sampling_rate_hz * self.settings.release_ms / 1000.0)))
        self._refractory_samples = max(0, int(math.ceil(self.sampling_rate_hz * self.settings.refractory_ms / 1000.0)))
        self._baseline_alpha = 1.0 - math.exp(-1.0 / (self.sampling_rate_hz * self.settings.baseline_tracking_seconds))
        self.reset()

    def reset(self) -> None:
        self._states = [_ChannelState(calibration=[]), _ChannelState(calibration=[])]

    @property
    def ready(self) -> tuple[bool, bool]:
        return tuple(state.ready for state in self._states)

    @property
    def baselines(self) -> tuple[float | None, float | None]:
        return tuple(state.baseline if state.ready else None for state in self._states)

    @staticmethod
    def _robust_location_scale(values: Iterable[float], floor: float) -> tuple[float, float]:
        array = np.asarray(tuple(values), dtype=np.float64)
        center = float(np.median(array))
        mad = float(np.median(np.abs(array - center)))
        # The relative floor prevents a nearly constant/digitized baseline from
        # producing a zero threshold; the absolute floor is in input RMS units.
        sigma = max(1.4826 * mad, abs(center) * 0.015, floor)
        return max(0.0, center), sigma

    def _finish_calibration(self, state: _ChannelState) -> None:
        state.baseline, state.sigma = self._robust_location_scale(
            state.calibration, self.settings.minimum_noise_floor
        )
        state.calibration.clear()
        state.ready = True

    def process(
        self,
        envelope_rms: np.ndarray,
        *,
        timestamps_ns: np.ndarray | None = None,
        valid_mask: np.ndarray | None = None,
    ) -> tuple[list[ContractionEvent], np.ndarray]:
        """Return (completed events, [samples,2] event-strength pulse arrays).

        The detector gathers the baseline from all finite samples during the
        initial quiet-calibration interval. `valid_mask` only gates event
        decisions after calibration; it is intended for transport/quality
        failures, not for MVC or task-vs-rest classification.
        """
        values = np.asarray(envelope_rms, dtype=np.float64)
        if values.ndim != 2 or values.shape[1] != 2:
            raise ValueError(f"Expected envelope shape [samples,2], got {values.shape}")
        count = values.shape[0]
        if timestamps_ns is None:
            times = None
        else:
            times = np.asarray(timestamps_ns, dtype=np.int64).reshape(-1)
            if times.size != count:
                raise ValueError("timestamps_ns length does not match envelope")
        if valid_mask is None:
            valid = np.isfinite(values)
        else:
            valid = np.asarray(valid_mask, dtype=bool)
            if valid.shape != values.shape:
                raise ValueError("valid_mask must have shape [samples,2]")
            valid &= np.isfinite(values)

        pulses = np.zeros_like(values, dtype=np.float64)
        events: list[ContractionEvent] = []

        for row in range(count):
            stamp = int(times[row]) if times is not None else None
            for channel, arm in enumerate(self.ARMS):
                if not self.enabled[channel]:
                    continue
                state = self._states[channel]
                value = float(values[row, channel])
                if not math.isfinite(value) or value < 0:
                    state.candidate_samples = 0
                    state.in_event = False
                    state.release_samples = 0
                    continue

                if not state.ready:
                    state.calibration.append(value)
                    if len(state.calibration) >= self._calibration_samples:
                        self._finish_calibration(state)
                    continue

                if not valid[row, channel]:
                    # A data-quality gap cancels a partial event so it cannot
                    # turn into a false contraction after reconnecting.
                    state.candidate_samples = 0
                    state.in_event = False
                    state.release_samples = 0
                    state.refractory_samples = self._refractory_samples
                    continue

                if state.refractory_samples > 0:
                    state.refractory_samples -= 1
                    continue

                onset = state.baseline + self.settings.onset_sigma * state.sigma
                release = state.baseline + self.settings.release_sigma * state.sigma

                if not state.in_event:
                    if state.candidate_samples == 0:
                        if value < onset:
                            # Slowly follow only quiet samples. Never learn an
                            # active contraction into the noise baseline.
                            delta = max(-3.0 * state.sigma, min(3.0 * state.sigma, value - state.baseline))
                            state.baseline = max(0.0, state.baseline + self._baseline_alpha * delta)
                            observed = abs(value - state.baseline) * 1.2533
                            state.sigma = max(
                                self.settings.minimum_noise_floor,
                                state.sigma + self._baseline_alpha * (min(observed, 3.0 * state.sigma) - state.sigma),
                            )
                            continue
                        state.peak = value
                        state.event_baseline = state.baseline
                        state.event_sigma = state.sigma
                        state.candidate_samples = 1
                    elif value > release:
                        # Hysteresis also applies during the debounce interval:
                        # a small dip below onset does not split one contraction.
                        state.peak = max(state.peak, value)
                        state.candidate_samples += 1
                    else:
                        state.candidate_samples = 0
                        state.peak = 0.0
                        continue

                    if state.candidate_samples >= self._min_samples:
                        state.in_event = True
                        state.release_samples = 0
                else:
                    state.peak = max(state.peak, value)
                    if value <= release:
                        state.release_samples += 1
                    else:
                        state.release_samples = 0

                    if state.release_samples >= self._release_samples:
                        base = state.event_baseline
                        sigma = max(state.event_sigma, self.settings.minimum_noise_floor)
                        normalized = (state.peak - base) / (self.settings.full_scale_sigma * sigma)
                        strength = float(np.clip(normalized, 0.0, 1.0))
                        event = ContractionEvent(
                            arm=arm,
                            strength=strength,
                            sample_index=row,
                            timestamp_ns=stamp,
                            peak_rms=state.peak,
                            baseline_rms=base,
                            noise_sigma=sigma,
                        )
                        events.append(event)
                        pulses[row, channel] = strength
                        state.in_event = False
                        state.candidate_samples = 0
                        state.release_samples = 0
                        state.refractory_samples = self._refractory_samples
                        state.peak = 0.0

        return events, pulses
