# A 2D point mutated in place through an alias. Exercises: multi-arg constructor, a method mutating
# TWO fields, a getter combining fields, and aliasing (move `q`, observe via `p`). Returns 33.
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def move(self, dx, dy):
        self.x = self.x + dx
        self.y = self.y + dy

    def manhattan(self):
        return self.x + self.y


def demo():
    p = Point(1, 2)
    q = p               # alias
    q.move(10, 20)      # p is now (11, 22)
    return p.manhattan()
