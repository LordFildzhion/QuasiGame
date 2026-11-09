"""SPEED-side transport adapter: contraction events -> local UDP packets.

This module knows nothing about the QuasiGame engine or its classes. The
receiver/adapter in Bridge.udp_game_bridge translates packets into GameAPI calls.
"""
from __future__ import annotations

import json
import math
import socket
import time
from typing import Iterable, Any

from Bridge.config import DEFAULT_UDP_HOST, DEFAULT_UDP_PORT


class GameBridgePublisher:
    def __init__(self, host: str = DEFAULT_UDP_HOST, port: int = DEFAULT_UDP_PORT) -> None:
        self.address = (str(host), int(port))
        if not 1 <= self.address[1] <= 65535:
            raise ValueError("UDP port must be in [1,65535]")
        # Monotonic across SPEED re-Prepare/restarts on this machine.
        self.sequence = time.monotonic_ns()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setblocking(False)

    def publish_events(self, events: Iterable[Any]) -> int:
        sent = 0
        for event in events:
            arm = str(getattr(event, "arm", ""))
            strength = float(getattr(event, "strength", float("nan")))
            if arm not in ("left", "right") or not math.isfinite(strength):
                continue
            strength = max(0.0, min(1.0, strength))
            self.sequence += 1
            message = {
                "version": 2,
                "type": "contraction",
                "seq": self.sequence,
                "arm": arm,
                "strength": strength,
                "timestamp_ns": getattr(event, "timestamp_ns", None),
                "peak_rms": float(getattr(event, "peak_rms", 0.0)),
            }
            payload = json.dumps(message, separators=(",", ":"), allow_nan=False).encode("utf-8")
            self.sock.sendto(payload, self.address)
            sent += 1
        return sent

    def close(self) -> None:
        self.sock.close()
