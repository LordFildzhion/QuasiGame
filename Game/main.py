"""QuasiGame entry points. Transport is injected through GameAPI."""
from __future__ import annotations

import argparse
from pathlib import Path

from .API.gameapi import GameAPI
from .GameEngine.GameConfig import GameConfig
from .GameEngine.GameLoop import GameLoop
from .GameEngine.GameObject import GameObject
from .GameEngine.Scene import Scene
from .GameEngine.UI.GameHUD import GameHUD
from .GameEngine.Components.Sprite import Sprite
from .GameEngine.Components.Fishingrod import Fishingrod
from .GameEngine.Components.FishController import FishController
from .GameEngine.Components.EMGInput import EMGInput


def create_scene(config: GameConfig, api: GameAPI, *, arm: str, keyboard: bool):
    """Build the scene; the engine sees GameAPI only, never the UDP bridge."""
    Scene.clear()
    background = GameObject()
    background.position = (0.5, 0.5)
    Sprite(background, 1, 1, "background.png")

    signal_object = GameObject()
    signal_object.tag = "emg"
    emg = EMGInput(signal_object, api, config.signal, channel=arm, keyboard=keyboard)

    line = GameObject()
    line.position = (0.2, 0.5)
    Sprite(line, 0.03, 0.09, "line.png")

    rod = GameObject()
    rod.tag = "rod"
    rod.position = (0.8, 0.15)
    Sprite(rod, 0.3, 0.3, "fishingrod.png")

    hook = GameObject()
    hook.tag = "hook"
    hook.position = (0.71, 0.9)
    Sprite(hook, 0.03, 0.03, "hook.png")
    Fishingrod(rod, line, hook)

    fish = GameObject()
    fish.position = (0.0, 1.0)
    fish.tag = "fish"
    Sprite(fish, 0.05, 0.05, "fish.png")
    controller = FishController(fish, config.fish, min_to_reel=config.signal.min_to_reel)

    water = GameObject()
    water.position = (0.5, 0.5)
    Sprite(water, 1, 1, "water.png")
    return emg, controller


def create_game(api: GameAPI, config: GameConfig | None = None,
                *, arm: str | None = None, keyboard: bool = False,
                config_path: str | Path | None = None):
    """Return (loop, HUD, EMG input, fish controller) for an external host."""
    selected_config = config or GameConfig.load(
        config_path or Path(__file__).with_name("Config.txt")
    )
    selected_arm = arm or selected_config.input.selected_arm
    if selected_arm not in ("left", "right"):
        raise ValueError("arm must be left or right")
    # Explicit keyboard=True or config's [input] keyboard=true enables demo mode.
    keyboard = bool(keyboard or selected_config.input.keyboard)
    # Renderer must initialize Pygame before Sprite loads image assets.
    loop = GameLoop()
    emg, fish = create_scene(selected_config, api, arm=selected_arm, keyboard=keyboard)
    hud = GameHUD(emg, fish, selected_config)
    return loop, hud, emg, fish


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, default=Path(__file__).with_name("Config.txt"))
    parser.add_argument("--channel", choices=("left", "right"), default=None)
    parser.add_argument("--keyboard", action="store_true")
    args = parser.parse_args()
    config = GameConfig.load(args.config)
    api = GameAPI()
    loop, hud, _emg, _fish = create_game(
        api, config, arm=args.channel, keyboard=args.keyboard
    )
    loop.run(hud)


if __name__ == "__main__":
    main()
