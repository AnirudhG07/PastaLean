# A stopwatch reset through an alias, then ticked once more. Exercises: reset (self.x = 0),
# interleaved mutations, and a reset happening through a second handle. Returns 1.
class Stopwatch:
    def __init__(self):
        self.ticks = 0

    def tick(self):
        self.ticks = self.ticks + 1

    def reset(self):
        self.ticks = 0

    def read(self):
        return self.ticks


def demo():
    sw = Stopwatch()
    sw.tick()
    sw.tick()
    sw.tick()          # ticks = 3
    handle = sw        # alias
    handle.reset()     # ticks = 0 (through the alias)
    sw.tick()          # ticks = 1
    return sw.read()
