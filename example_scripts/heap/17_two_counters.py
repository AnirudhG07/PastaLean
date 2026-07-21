# Two SEPARATE objects (no aliasing): each `Counter()` is a distinct heap allocation, so mutating
# one does not affect the other. Contrast with 13_aliasing. Returns 3 (a=2, b=1).
class Counter:
    def __init__(self):
        self.n = 0

    def inc(self):
        self.n = self.n + 1

    def get(self):
        return self.n


def demo():
    a = Counter()
    b = Counter()      # a DIFFERENT object
    a.inc()
    a.inc()
    b.inc()
    return a.get() + b.get()
