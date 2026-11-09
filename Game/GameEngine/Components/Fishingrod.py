from pygame import Vector2
from ..Component import Component
from .Sprite import Sprite

from ..GameObject import GameObject


class Fishingrod(Component):
    name = "fishingrod"
    def __init__(self, object, line, hook):
        super().__init__(object)
        self.line: GameObject = line
        self.hook: GameObject = hook


    def start(self) -> None:
        sprite: Sprite = self.gameObject.getComponent(Sprite.name)
        self.width = sprite.width
        self.height = sprite.height
        self.lineSprite: Sprite = self.line.getComponent(Sprite.name)

    def update(self) -> None:
        self.updateLine()


    def updateLine(self) -> None:
        strtPos = self.getEndPod()
        endPos = self.hook.position
        self.line.position = (strtPos + endPos)/2

        dir: Vector2 = strtPos - endPos
        self.line.rotation = -Vector2(0,1).angle_to(dir)

        self.lineSprite.resize(self.lineSprite.width,dir.length())

    def getEndPod(self) -> Vector2:
        offset: Vector2 = Vector2(-0.29, -0.49)
        offset = offset.elementwise() * Vector2(self.width, self.height)
        offset = offset.rotate(-self.gameObject.rotation)
        offset = offset + Vector2(self.gameObject.position)
        return offset
