"""Game-side EMG input. Test and live events use the same signal settings."""
from __future__ import annotations

from dataclasses import replace
import math
import time

import pygame
from ..Component import Component
from ..GameConfig import SignalSettings
from ...API.gameapi import GameAPI, ContractionSignal


class EMGInput(Component):
    name = "emg_input"

    def __init__(self, game_object, api: GameAPI, settings: SignalSettings,
                 channel: str = "right", keyboard: bool = False):
        super().__init__(game_object)
        self.api = api
        self.settings = settings
        self.channel = channel
        self.demo = bool(keyboard)
        self.activity: float | None = None
        self.last_event: ContractionSignal | None = None
        self.events: list[ContractionSignal] = []
        self.total_events = 0
        self.test_level = float(settings.keyboard_strength)
        self._pressed_t = False
        self._pressed_tab = False
        self._pressed_space = False
        self._test_sequence = 0
        self._smooth_strength: float | None = None
        self._smooth_time_ns: int | None = None

    def start(self) -> None:
        pass

    def _reset_smoothing(self) -> None:
        self._smooth_strength = None
        self._smooth_time_ns = None

    def _transform(self, event: ContractionSignal) -> ContractionSignal:
        scaled = self.settings.scale(event.strength)
        if self.settings.debug:
            print("Got signal: row = " + str(event.strength) + " transformed = " + str(scaled))
        if scaled is None:
            # GameAPI already validates event values; defensive fallback.
            scaled = 0.0
        tau = self.settings.smoothing_seconds
        if tau > 0 and self._smooth_strength is not None and self._smooth_time_ns is not None:
            delta = max(0.0, (event.timestamp_ns - self._smooth_time_ns) / 1e9)
            alpha = -math.expm1(-delta / tau)
            scaled = self._smooth_strength + alpha * (scaled - self._smooth_strength)
        self._smooth_strength = scaled
        self._smooth_time_ns = event.timestamp_ns
        return replace(event, strength=scaled)

    def update(self) -> None:
        keys = pygame.key.get_pressed()
        t = bool(keys[pygame.K_t])
        if t and not self._pressed_t:
            self.demo = not self.demo
            self._reset_smoothing()
        self._pressed_t = t

        tab = bool(keys[pygame.K_TAB])
        if tab and not self._pressed_tab:
            self.channel = "left" if self.channel == "right" else "right"
            self._reset_smoothing()
        self._pressed_tab = tab

        up = bool(keys[pygame.K_UP])
        down = bool(keys[pygame.K_DOWN])
        incoming: list[ContractionSignal]
        if self.demo:
            adjustment = int(up) - int(down)
            self.test_level = max(0.0, min(1.0, self.test_level + adjustment * 0.45 / 60.0))
            space = bool(keys[pygame.K_SPACE])
            incoming = []
            if space and not self._pressed_space:
                self._test_sequence += 1
                incoming.append(ContractionSignal(
                    arm=self.channel,
                    strength=self.test_level,
                    sequence=self._test_sequence,
                    timestamp_ns=time.time_ns(),
                ))
            self._pressed_space = space
            # Intentional keyboard test mode: don't mix in live packets.
            self.api.drain_events()
        else:
            incoming = self.api.drain_events(self.channel)
            self._pressed_space = False

        self.events = [self._transform(event) for event in incoming]
        if self.events:
            self.last_event = self.events[-1]
            self.activity = self.last_event.strength
            self.total_events += len(self.events)
        elif self.last_event is not None:
            self.activity = self.last_event.strength

    def stop(self) -> None:
        pass
