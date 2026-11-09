"""Small, stable public API used by the Bridge to control the game."""
from __future__ import annotations

from dataclasses import dataclass
from queue import Empty, SimpleQueue
import itertools
import math
import time


@dataclass(frozen=True)
class ContractionSignal:
    arm: str
    strength: float
    sequence: int
    timestamp_ns: int


class GameAPI:
    """Thread-safe event inbox. No UDP, LSL, Resonance or Pygame dependencies."""
    def __init__(self) -> None:
        self._events: SimpleQueue[ContractionSignal] = SimpleQueue()
        self._local_sequence = itertools.count(1)

    def emit_contraction(
        self,
        arm: str,
        strength: float,
        *,
        sequence: int | None = None,
        timestamp_ns: int | None = None,
    ) -> ContractionSignal:
        arm = str(arm).lower()
        value = float(strength)
        if arm not in ("left", "right"):
            raise ValueError("arm must be 'left' or 'right'")
        if not math.isfinite(value):
            raise ValueError("strength must be finite")
        value = max(0.0, min(1.0, value))
        event = ContractionSignal(
            arm=arm,
            strength=value,
            sequence=int(sequence) if sequence is not None else next(self._local_sequence),
            timestamp_ns=int(timestamp_ns) if timestamp_ns is not None else time.time_ns(),
        )
        self._events.put(event)
        return event

    # Compatibility names for a simple external API contract.
    def signalFromLeftArm(self, strength: float) -> ContractionSignal:
        return self.emit_contraction("left", strength)

    def signalFromRightArm(self, strength: float) -> ContractionSignal:
        return self.emit_contraction("right", strength)

    def drain_events(self, arm: str | None = None) -> list[ContractionSignal]:
        if arm is not None and arm not in ("left", "right"):
            raise ValueError("arm must be left, right or None")
        result: list[ContractionSignal] = []
        while True:
            try:
                event = self._events.get_nowait()
            except Empty:
                break
            if arm is None or event.arm == arm:
                result.append(event)
        return result
