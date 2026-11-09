"""Validated user-editable settings; compatible with the existing Config.txt."""
from __future__ import annotations

from configparser import ConfigParser
from dataclasses import dataclass
from pathlib import Path
import math


@dataclass(frozen=True)
class FishSettings:
    # Old controller: while hooked, drift toward (0, 1) at speed 0.5.
    speed: float = 0.50
    # Old pulling speed is 1/strength: multiplier defaults to 1.0.
    reel_speed_multiplier: float = 1.0
    slip_speed_multiplier: float = 2.0
    catch_pause_seconds: float = 1.0
    slip_trigger_distance: float = 0.0
    # Maximum dt consumed by one old-style EMG callback; NOT an active impulse.
    reel_impulse_seconds: float = 0.10
    # Original rule: stronger signal >0.1 makes fish slip off immediately.
    slip_strength_threshold: float = 0.10
    # Original catch condition: fish position.y <0.3.
    catch_y: float = 0.30

    def __post_init__(self):
        for name in ("speed", "reel_speed_multiplier", "slip_speed_multiplier"):
            value = getattr(self, name)
            if not math.isfinite(value) or value <= 0:
                raise ValueError(f"fish.{name} must be finite and positive")
        if not math.isfinite(self.catch_pause_seconds) or self.catch_pause_seconds < 0:
            raise ValueError("fish.catch_pause_seconds must be finite and nonnegative")
        if not math.isfinite(self.slip_trigger_distance) or not 0 <= self.slip_trigger_distance <= 0.50:
            raise ValueError("fish.slip_trigger_distance must be in [0, 0.50]")
        if not math.isfinite(self.reel_impulse_seconds) or self.reel_impulse_seconds <= 0:
            raise ValueError("fish.reel_impulse_seconds must be positive")
        if not math.isfinite(self.slip_strength_threshold) or not 0 <= self.slip_strength_threshold <= 1:
            raise ValueError("fish.slip_strength_threshold must be in [0, 1]")
        if not math.isfinite(self.catch_y) or not 0 <= self.catch_y <= 1:
            raise ValueError("fish.catch_y must be in [0, 1]")


@dataclass(frozen=True)
class SignalSettings:
    multiplier: float = 1.0
    min_to_reel: float = 0.02
    keyboard_strength: float = 0.06
    smoothing_seconds: float = 0.0

    def __post_init__(self):
        if not math.isfinite(self.multiplier) or self.multiplier <= 0:
            raise ValueError("signal.multiplier must be finite and positive")
        for name in ("min_to_reel", "keyboard_strength"):
            value = getattr(self, name)
            if not math.isfinite(value) or not 0 <= value <= 1:
                raise ValueError(f"signal.{name} must be in [0, 1]")
        if not math.isfinite(self.smoothing_seconds) or self.smoothing_seconds < 0:
            raise ValueError("signal.smoothing_seconds must be finite and nonnegative")

    def scale(self, raw_strength: float | None) -> float | None:
        if raw_strength is None or not math.isfinite(raw_strength):
            return None
        return max(0.0, min(1.0, raw_strength * self.multiplier))


@dataclass(frozen=True)
class InputSettings:
    selected_arm: str = "right"
    keyboard: bool = False

    def __post_init__(self):
        if self.selected_arm not in {"left", "right"}:
            raise ValueError("input.selected_arm must be left or right")


@dataclass(frozen=True)
class GameConfig:
    fish: FishSettings = FishSettings()
    signal: SignalSettings = SignalSettings()
    input: InputSettings = InputSettings()

    @classmethod
    def load(cls, filename: str | Path) -> "GameConfig":
        filename = Path(filename)
        if not filename.is_file():
            raise FileNotFoundError(f"Game config not found: {filename}")
        parser = ConfigParser(inline_comment_prefixes=("#", ";"))
        parser.read(filename, encoding="utf-8-sig")

        def get(section, key, fallback, convert):
            try:
                return convert(parser.get(section, key, fallback=str(fallback)))
            except ValueError as exc:
                raise ValueError(f"Invalid [{section}] {key}: {exc}") from exc

        defaults = FishSettings()
        fish = FishSettings(
            speed=get("fish", "speed", defaults.speed, float),
            reel_speed_multiplier=get("fish", "reel_speed_multiplier", defaults.reel_speed_multiplier, float),
            slip_speed_multiplier=get("fish", "slip_speed_multiplier", defaults.slip_speed_multiplier, float),
            catch_pause_seconds=get("fish", "catch_pause_seconds", defaults.catch_pause_seconds, float),
            slip_trigger_distance=get("fish", "slip_trigger_distance", defaults.slip_trigger_distance, float),
            reel_impulse_seconds=get("fish", "reel_impulse_seconds", defaults.reel_impulse_seconds, float),
            slip_strength_threshold=get("fish", "slip_strength_threshold", defaults.slip_strength_threshold, float),
            catch_y=get("fish", "catch_y", defaults.catch_y, float),
        )
        sig_def = SignalSettings()
        signal = SignalSettings(
            multiplier=get("signal", "multiplier", sig_def.multiplier, float),
            min_to_reel=get("signal", "min_to_reel", sig_def.min_to_reel, float),
            keyboard_strength=get("signal", "keyboard_strength", sig_def.keyboard_strength, float),
            smoothing_seconds=get("signal", "smoothing_seconds", sig_def.smoothing_seconds, float),
        )
        section = "input" if parser.has_section("input") else "connection"
        try:
            keyboard = parser.getboolean(section, "keyboard", fallback=False)
        except ValueError as exc:
            raise ValueError(f"Invalid [{section}] keyboard flag") from exc
        input_settings = InputSettings(
            selected_arm=parser.get(section, "selected_arm", fallback="right").strip().lower(),
            keyboard=keyboard,
        )
        return cls(fish, signal, input_settings)
