"""Small OOP primitives for 2D overlays."""
from __future__ import annotations
from abc import ABC, abstractmethod
import pygame


class Widget(ABC):
    @abstractmethod
    def draw(self, surface: pygame.Surface) -> None:
        ...


class UIContainer(Widget):
    def __init__(self, children: list[Widget] | None = None):
        self.children = list(children or [])

    def add(self, child: Widget) -> None:
        self.children.append(child)

    def draw(self, surface: pygame.Surface) -> None:
        for child in self.children:
            child.draw(surface)


class Label(Widget):
    def __init__(self, value, position, size=18, color=(238, 246, 250)):
        self.value = value  # callable: UI information is read from state objects
        self.position = position
        self.size = size
        self.color = color
        self._font = None

    def draw(self, surface: pygame.Surface) -> None:
        if self._font is None:
            self._font = pygame.font.SysFont("consolas", self.size) or pygame.font.Font(None, self.size)
        surface.blit(self._font.render(str(self.value()), True, self.color), self.position())


class HorizontalGauge(Widget):
    def __init__(self, value, rect, label="EMG", foreground=(80, 206, 135)):
        self.value = value
        self.rect = rect
        self.label = label
        self.foreground = foreground

    def draw(self, surface: pygame.Surface) -> None:
        rect = pygame.Rect(self.rect(surface))
        pygame.draw.rect(surface, (52, 64, 75), rect, border_radius=4)
        value = self.value()
        if value is not None:
            fill = rect.copy()
            fill.width = max(0, int(rect.width * max(0.0, min(1.0, float(value)))))
            if fill.width:
                pygame.draw.rect(surface, self.foreground, fill, border_radius=4)
        pygame.draw.rect(surface, (204, 215, 224), rect, 1, border_radius=4)


class DarkPanel(Widget):
    def __init__(self, rect):
        self.rect = rect

    def draw(self, surface: pygame.Surface) -> None:
        panel_rect = pygame.Rect(self.rect(surface))
        overlay = pygame.Surface(panel_rect.size, pygame.SRCALPHA)
        overlay.fill((14, 29, 42, 215))
        surface.blit(overlay, panel_rect.topleft)
