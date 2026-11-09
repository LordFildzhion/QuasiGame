"""Composition root for the game loop and optional UI overlay."""
import pygame
from .Renderer import Renderer
from .Scene import Scene
from .Time import Time
from .Globals import Globals


class GameLoop:
    def __init__(self):
        self.renderer = Renderer(*Globals.screenSize)
        self.running = False

    def run(self, overlay=None):
        self.running = True
        components = [comp for obj in Scene.objects for comp in obj.components.values()]
        started = []
        try:
            for comp in components:
                comp.start()
                started.append(comp)
            while self.running:
                Time.update(self.renderer.clock.tick(60))
                for event in pygame.event.get():
                    if event.type == pygame.QUIT or (event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE):
                        self.running = False
                    elif event.type == pygame.VIDEORESIZE:
                        self.renderer.on_resize()
                if not self.running:
                    break
                for comp in components:
                    comp.update()
                self.renderer.draw_scene()
                if overlay is not None:
                    overlay.draw(self.renderer.screen)
                self.renderer.present()
        finally:
            for comp in reversed(started):
                stop = getattr(comp, "stop", None)
                if callable(stop):
                    stop()
            pygame.quit()
