from enum import Enum, auto
import math

from pygame import Vector2

from ..Component import Component
from ..GameConfig import FishSettings
from ..Scene import Scene
from ..Time import Time
from .EMGInput import EMGInput
from .Fishingrod import Fishingrod


class FishingState(Enum):
    SWIMMING = auto()
    HOOKED = auto()
    PULLED_OUT = auto()
    SLIPPED_OFF = auto()


class FishController(Component):
    name = "fishcon"

    def __init__(self, game_object, settings: FishSettings,
                 min_to_reel: float = 0.02):
        super().__init__(game_object)
        self.settings = settings
        self.min_to_reel = float(min_to_reel)
        if not math.isfinite(self.min_to_reel) or not 0 <= self.min_to_reel <= 1:
            raise ValueError("min_to_reel must be finite and between 0 and 1")

        self.state = FishingState.SWIMMING
        self.spawn_position = Vector2(game_object.position)
        self.escape_position = Vector2(0, 1)
        self.delay = 0.0
        self.catches = 0
        self.escapes = 0

        self.hook = None
        self.hook_start = None
        self.rod = None
        self.signal = None

    @property
    def status(self) -> str:
        return {
            FishingState.SWIMMING: "Swimming toward hook",
            FishingState.HOOKED: "Hooked: contract gently to reel in",
            FishingState.PULLED_OUT: "Caught! Preparing next fish",
            FishingState.SLIPPED_OFF: "Fish escaped",
        }[self.state]

    def start(self) -> None:
        hook = Scene.findObjectWithTag("hook")
        rod_object = Scene.findObjectWithTag("rod")
        signal_object = Scene.findObjectWithTag("emg")
        if hook is None or rod_object is None or signal_object is None:
            raise RuntimeError("Fishing scene is missing hook, rod or emg object")

        rod = rod_object.getComponent(Fishingrod.name)
        signal = signal_object.getComponent(EMGInput.name)
        if rod is None or signal is None:
            raise RuntimeError("Fishing scene is missing Fishingrod or EMGInput component")

        self.hook = hook
        self.hook_start = Vector2(hook.position)
        self.rod = rod
        self.signal = signal

    def update(self) -> None:
        """Move once per frame; apply each contraction just like old wasHooked()."""
        dt = max(0.0, float(Time.deltaTime))
        if self.state is FishingState.SWIMMING:
            if self.moove(self.hook.position, self.settings.speed * self.settings.slip_speed_multiplier, dt):
                self.state = FishingState.HOOKED

        elif self.state is FishingState.HOOKED:
            arrived = self.moove(self.escape_position, self.settings.speed, dt)
            if arrived or (Vector2(self.gameObject.position) - self.escape_position).length() <= self.settings.slip_trigger_distance:
                self._slip_off()

        elif self.state is FishingState.PULLED_OUT:
            self.delay -= dt
            if self.delay <= 0.0:
                self.state = FishingState.SWIMMING
                self.gameObject.position = Vector2(self.spawn_position)

        elif self.state is FishingState.SLIPPED_OFF:
            if self.moove(self.escape_position,
                          self.settings.speed * self.settings.slip_speed_multiplier,
                          dt):
                self.state = FishingState.SWIMMING


        for event in self.signal.events:
            self.wasHooked(event.strength, dt)

        if self.state in (FishingState.HOOKED, FishingState.PULLED_OUT):
            self.hook.position = Vector2(self.gameObject.position)
        else:
            self.hook.position = Vector2(self.hook_start)

    def moove(self, pos, speed: float, dt: float | None = None) -> bool:
        """Preserve old public method name, without overshooting the target."""
        dt = float(Time.deltaTime) if dt is None else float(dt)
        if not math.isfinite(dt) or dt <= 0.0:
            return (Vector2(pos) - Vector2(self.gameObject.position)).length() == 0
        target = Vector2(pos)
        current = Vector2(self.gameObject.position)
        direction = target - current
        distance = direction.length()
        step = max(0.0, speed * dt)
        if distance <= step:
            self.gameObject.position = target
            return True
        if distance > 0:
            self.gameObject.position = current + direction * (step / distance)
        return False

    def wasHooked(self, val: float, dt: float | None = None) -> None:
        if self.state is not FishingState.HOOKED:
            return
        value = float(val)
        if not math.isfinite(value):
            return
        if value > self.settings.slip_strength_threshold:
            self._slip_off()
            return

        strength = max(value, self.min_to_reel, 1e-6)
        reel_speed = self.settings.reel_speed_multiplier / strength
        dt = max(0.0, float(Time.deltaTime if dt is None else dt))

        step_dt = min(dt, self.settings.reel_impulse_seconds)
        self.moove(self.rod.getEndPod(), reel_speed, step_dt)

        if self.gameObject.position[1] < self.settings.catch_y:
            self.state = FishingState.PULLED_OUT
            self.delay = self.settings.catch_pause_seconds
            self.catches += 1

    def _slip_off(self) -> None:
        if self.state is FishingState.HOOKED:
            self.state = FishingState.SLIPPED_OFF
            self.escapes += 1
