"""Regression tests for the shipped SPEED -> Bridge event configuration."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[3]
MULINES = ROOT / "Resonance" / "mulines"
sys.path.insert(0, str(MULINES))

from configured_speed import read_settings  # noqa: E402


class ConfiguredSpeedSettingsTests(unittest.TestCase):
    def test_current_profile_uses_separate_bridge_and_event_mode(self):
        settings = read_settings(ROOT / "Resonance" / "params" / "speed_configurator.txt")
        self.assertTrue(settings.bridge_enabled)
        self.assertEqual(settings.bridge_host, "127.0.0.1")
        self.assertEqual(settings.bridge_port, 8765)
        self.assertEqual(settings.event_detector.onset_sigma, 4.0)
        self.assertEqual(settings.event_detector.min_contraction_ms, 20.0)


if __name__ == "__main__":
    unittest.main()
