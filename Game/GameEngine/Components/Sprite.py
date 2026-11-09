from pathlib import Path
import pygame

from ..Component import Component
from ..GameObject import GameObject
from ..Globals import Globals

RESOURCES = Path(__file__).parent.parent.parent / "Resources"


class Sprite(Component):
    name = "Sprite"

    def __init__(self, object, width, height, image):
        super().__init__(object)

        path = RESOURCES / image
        if not path.exists():
            raise FileNotFoundError(f"Нет файла: {path}")
        self.original = pygame.image.load(str(path)).convert_alpha()

        self.width  = width
        self.height = height
        self.image = self.original
        self.applyScale()

    def applyScale(self):
        base = Globals.screenSize[0]
        if self.width and self.height:
            w = max(1, int(self.width  * base))
            h = max(1, int(self.height * base))
            self.image = pygame.transform.smoothscale(self.original, (w, h))
        else:
            self.image = self.original

    def resize(self, w, h):
        self.width, self.height = w, h
        self.applyScale()

    def start(self): pass
    def update(self): pass