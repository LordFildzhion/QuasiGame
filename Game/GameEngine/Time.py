class Time:
    deltaTime: float = 0.0
    unscaledDeltaTime: float = 0.0
    time: float = 0.0
    frameCount: int = 0
    timeScale: float = 1.0

    @classmethod
    def update(cls, ms_from_clock: int) -> None:
        cls.unscaledDeltaTime = ms_from_clock / 1000.0
        cls.deltaTime = cls.unscaledDeltaTime * cls.timeScale
        cls.time += cls.unscaledDeltaTime
        cls.frameCount += 1