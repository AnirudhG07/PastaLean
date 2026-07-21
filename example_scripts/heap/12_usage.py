# A class defined AND used (instantiated + field read) in a function.
# Exercises: the prelude coexisting with value-mode construction/attribute access at call sites
# (real aliasing here is Stage 2; this confirms the universe does not disturb ordinary use).
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y


def make():
    p = Point(1, 2)
    return p.x
