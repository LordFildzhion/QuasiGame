from __future__ import annotations

from pygame.math import Vector2
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .Component import Component

from .Scene import Scene


class GameObject:
    def __init__(self):
        self._position = Vector2()
        self.rotation = 0.0
        self.components: dict[str, Component] = {}
        Scene.objects.append(self)
        self.tag: str = None

    @property
    def position(self) -> Vector2:
        return self._position

    @position.setter
    def position(self, value) -> None:
        self._position = Vector2(value)

    def getComponent(self, component: str) -> Component:
        return self.components.get(component)