"""Fishing HUD. Reads status directly from FishController (no session object)."""
from .Widgets import UIContainer, Label, HorizontalGauge, DarkPanel


class GameHUD(UIContainer):
    def __init__(self, emg, fish, config):
        super().__init__()
        self.emg = emg
        self.fish = fish
        self.config = config
        width = lambda screen: max(240, min(500, screen.get_width() - 32))
        pos = lambda x, y: lambda: (x, y)
        self.add(DarkPanel(lambda screen: (10, 8, width(screen) + 20, 176)))
        self.add(Label(self._signal_line, pos(20, 16), 19))
        self.add(Label(self._count_line, pos(20, 42), 18))
        self.add(Label(lambda: self.fish.status, pos(20, 68), 15))
        self.add(Label(self._settings_line, pos(20, 92), 15))
        self.add(HorizontalGauge(lambda: self.emg.activity,
                                 lambda screen: (20, 117, width(screen), 17)))
        self.add(Label(lambda: f"CONTRACTIONS: {self.emg.total_events}   Last EMG strength: {self.emg.activity if self.emg.activity is not None else '--'}",
                       pos(20, 140), 13))
        self.add(Label(lambda: "T: test/live  TAB: arm  SPACE: one contraction  UP/DOWN: strength",
                       pos(20, 158), 12))

    def _signal_line(self):
        strength = "--" if self.emg.activity is None else f"{self.emg.activity:.3f}"
        source = "KEYBOARD" if self.emg.demo else "BRIDGE / UDP"
        return f"{source}  {self.emg.channel.upper()}  LAST CONTRACTION: {strength}"

    def _count_line(self):
        return f"CAUGHT: {self.fish.catches}     ESCAPED: {self.fish.escapes}"

    def _settings_line(self):
        s = self.config.fish
        return (f"Drift {self.fish.speed:g}  Reel x{s.reel_speed_multiplier:g}  "
                f"Slip >{self.fish.slip_strength:g}  Low=strong")
