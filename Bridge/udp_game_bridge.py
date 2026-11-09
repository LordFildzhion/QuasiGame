"""Game-side UDP receiver. This is the only adapter between UDP and GameAPI."""
from __future__ import annotations

import json
import math
import socket
import threading
from typing import TYPE_CHECKING

from Bridge.config import DEFAULT_UDP_HOST, DEFAULT_UDP_PORT

if TYPE_CHECKING:
    from Game.API.gameapi import GameAPI


class UDPGameBridge:
    def __init__(self, api: "GameAPI", host: str = DEFAULT_UDP_HOST, port: int = DEFAULT_UDP_PORT) -> None:
        self.api = api
        self.address = (str(host), int(port))
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.settimeout(0.20)
        try:
            self.socket.bind(self.address)
        except OSError:
            self.socket.close()
            raise
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None
        self._last_sequence = 0
        self.received = 0
        self.rejected = 0

    @staticmethod
    def decode(payload: bytes) -> dict | None:
        try:
            data = json.loads(payload.decode("utf-8"))
            if not isinstance(data, dict) or data.get("version") != 2 or data.get("type") != "contraction":
                return None
            arm = data.get("arm")
            strength = float(data.get("strength"))
            seq = int(data.get("seq"))
            timestamp = data.get("timestamp_ns")
            if arm not in ("left", "right") or seq <= 0 or not math.isfinite(strength):
                return None
            if not 0.0 <= strength <= 1.0:
                return None
            if timestamp is not None:
                timestamp = int(timestamp)
            return {"arm": arm, "strength": strength, "seq": seq, "timestamp_ns": timestamp}
        except (UnicodeDecodeError, json.JSONDecodeError, TypeError, ValueError, OverflowError):
            return None

    def start(self) -> None:
        if self._thread is not None and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(target=self._run, name="QuasiGame-UDP-Bridge", daemon=True)
        self._thread.start()

    def _run(self) -> None:
        while not self._stop.is_set():
            try:
                payload, _sender = self.socket.recvfrom(4096)
            except socket.timeout:
                continue
            except OSError:
                if self._stop.is_set():
                    break
                self.rejected += 1
                continue
            packet = self.decode(payload)
            if packet is None or packet["seq"] <= self._last_sequence:
                self.rejected += 1
                continue
            self._last_sequence = packet["seq"]
            self.api.emit_contraction(
                packet["arm"],
                packet["strength"],
                sequence=packet["seq"],
                timestamp_ns=packet["timestamp_ns"],
            )
            self.received += 1

    def close(self) -> None:
        self._stop.set()
        try:
            self.socket.close()
        except OSError:
            pass
        if self._thread is not None:
            self._thread.join(timeout=1.0)
            self._thread = None
