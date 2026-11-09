"""Only scene sprite rendering; HUD widgets live in GameEngine.UI."""
import pygame
from .Scene import Scene
from .Components.Sprite import Sprite
from .Globals import Globals


class Renderer:
    def __init__(self, width: int, height: int):
        pygame.init()
        self.screen = pygame.display.set_mode((width, height), pygame.RESIZABLE)
        pygame.display.set_caption("QuasiGame — EMG Fishing")
        self.clock = pygame.time.Clock()
        self.rebuild_buffer()

    def rebuild_buffer(self):
        w, h = self.screen.get_size()
        size = max(w, h)
        self.buffer = pygame.Surface((size, size)).convert()
        self.buffer_size = size
        Globals.screenSize = (size, size)
        for obj in Scene.objects:
            sprite = obj.components.get(Sprite.name)
            if sprite is not None:
                sprite.applyScale()

    def on_resize(self):
        self.rebuild_buffer()

    def draw_scene(self):
        size = self.buffer_size
        self.buffer.fill((20, 30, 50))
        for obj in Scene.objects:
            sprite = obj.components.get(Sprite.name)
            if sprite is None:
                continue
            rotated = pygame.transform.rotate(sprite.image, obj.rotation)
            rect = rotated.get_rect(center=(obj.position[0] * size, obj.position[1] * size))
            self.buffer.blit(rotated, rect)
        pygame.transform.scale(self.buffer, self.screen.get_size(), self.screen)

    def present(self):
        pygame.display.flip()
