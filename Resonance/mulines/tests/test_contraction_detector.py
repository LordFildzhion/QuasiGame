"""Synthetic regression tests for single-event detection and micro-burst sensitivity."""
import sys
from pathlib import Path
import unittest

import numpy as np
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from contraction_detector import ContractionDetectorSettings, ContractionEventDetector


class DetectorTests(unittest.TestCase):
    def make_input(self, burst_intervals, amplitude=0.25e-6, seed=12):
        fs = 500
        rng = np.random.default_rng(seed)
        noise = rng.normal(0.0, 0.025e-6, 2600)
        envelope = np.maximum(0.8e-6 + noise, 0.0)
        for start, end in burst_intervals:
            envelope[start:end] += amplitude
        matrix = np.column_stack((envelope, envelope * 0.8))
        return fs, matrix

    def detector(self, fs=500):
        settings = ContractionDetectorSettings(
            calibration_seconds=1.0,
            onset_sigma=4.0,
            release_sigma=1.5,
            min_contraction_ms=20,
            release_ms=28,
            refractory_ms=65,
            full_scale_sigma=14,
        )
        return ContractionEventDetector(fs, settings)

    def test_one_sustained_contraction_is_exactly_one_event_per_arm(self):
        fs, values = self.make_input([(800, 900)], amplitude=.5e-6)
        detector = self.detector(fs)
        events, pulses = detector.process(values)
        self.assertEqual(len(events), 2)  # one event from each configured hand
        self.assertEqual(sum(1 for value in pulses[:, 0] if value > 0), 1)
        self.assertEqual(sum(1 for value in pulses[:, 1] if value > 0), 1)
        self.assertTrue(all(0 <= event.strength <= 1 for event in events))

    def test_two_distinct_contractions_produce_two_events_per_arm(self):
        fs, values = self.make_input([(800, 900), (1500, 1600)], amplitude=.5e-6)
        detector = self.detector(fs)
        events, _ = detector.process(values)
        self.assertEqual(sum(event.arm == "left" for event in events), 2)
        self.assertEqual(sum(event.arm == "right" for event in events), 2)

    def test_weak_micro_burst_above_noise_is_detected(self):
        fs, values = self.make_input([(800, 845)], amplitude=.18e-6)
        detector = self.detector(fs)
        events, _ = detector.process(values)
        left_events = [event for event in events if event.arm == "left"]
        self.assertEqual(len(left_events), 1)
        self.assertGreater(left_events[0].strength, 0.0)

    def test_noise_only_does_not_generate_contractions(self):
        fs = 500
        rng = np.random.default_rng(42)
        noise = rng.normal(0.0, 0.025e-6, fs * 20)
        envelope = np.maximum(0.8e-6 + noise, 0.0)
        values = np.column_stack((envelope, envelope * 0.8))
        detector = self.detector(fs)
        events, _ = detector.process(values)
        self.assertEqual(events, [])

    def test_single_sample_noise_spike_is_rejected(self):
        fs, values = self.make_input([], amplitude=0.0)
        values[800, 0] += 2e-6
        detector = self.detector(fs)
        events, _ = detector.process(values)
        self.assertEqual(events, [])

    def test_disabled_channel_never_emits(self):
        fs, values = self.make_input([(800, 900)], amplitude=.8e-6)
        detector = ContractionEventDetector(fs, self.detector(fs).settings, enabled=(False, True))
        events, _ = detector.process(values)
        self.assertTrue(all(event.arm == "right" for event in events))

    def test_calibration_readiness_after_quiet_window(self):
        fs, values = self.make_input([], amplitude=0.0)
        detector = self.detector(fs)
        self.assertEqual(detector.ready, (False, False))
        detector.process(values[:500])
        self.assertEqual(detector.ready, (True, True))


if __name__ == '__main__':
    unittest.main()
