from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .GameObject import GameObject


class Scene:
    objects: list["GameObject"] = []

    @classmethod
    def clear(self):
        self.objects: list[GameObject] = []

    @classmethod
    def findObjectWithTag(self, tag: str) -> GameObject:
        for obj in self.objects:
            if obj.tag == tag:
                return obj
        return None
        