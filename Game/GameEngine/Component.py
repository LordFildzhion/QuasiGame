from abc import ABC, abstractmethod

from .GameObject import GameObject

class Component(ABC):
    name: str = None

    def __init__(self, object: GameObject):
        super().__init__()
        if object is None:
            raise ValueError("object не может быть None")
        if self.name is None:
            raise ValueError("name не может быть None")
        self.gameObject = object
        self.gameObject.components[self.name] = self

    @abstractmethod
    def start(self) -> None: ...

    @abstractmethod
    def update(self) -> None: ...
