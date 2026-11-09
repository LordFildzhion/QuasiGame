"""Composition root: GameAPI + optional UDP Bridge + QuasiGame engine."""
from __future__ import annotations

import argparse
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from Game.API.gameapi import GameAPI
from Game.GameEngine.GameConfig import GameConfig
from Game.main import create_game
from Bridge.config import DEFAULT_UDP_HOST, DEFAULT_UDP_PORT
from Bridge.udp_game_bridge import UDPGameBridge


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=PROJECT_ROOT / "Game" / "Config.txt")
    parser.add_argument("--host", default=DEFAULT_UDP_HOST)
    parser.add_argument("--port", type=int, default=DEFAULT_UDP_PORT)
    parser.add_argument("--channel", choices=("left", "right"), default=None)
    parser.add_argument("--keyboard", action="store_true", help="Use Space keypresses as test contractions")
    args = parser.parse_args()

    config = GameConfig.load(args.config)
    port = args.port
    arm = args.channel or config.input.selected_arm
    api = GameAPI()
    loop, hud, _emg, _fish = create_game(api, config, arm=arm, keyboard=args.keyboard)

    bridge = None
    if not args.keyboard:
        try:
            bridge = UDPGameBridge(api, host=args.host, port=port)
            bridge.start()
        except OSError as exc:
            raise RuntimeError(
                f"Не удалось открыть UDP {args.host}:{port}. Возможно, игра уже запущена: {exc}"
            ) from exc
        print(f"QuasiGame ready: Bridge UDP {args.host}:{port}, selected arm={arm}", flush=True)
    else:
        print("QuasiGame keyboard test: press Space once per contraction; hold does not repeat", flush=True)

    try:
        loop.run(hud)
    finally:
        if bridge is not None:
            bridge.close()


if __name__ == "__main__":
    main()
