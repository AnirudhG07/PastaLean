# A class whose fields are OTHER user classes (nested value structs, HeapSL's Point/Line).
# Exercises: prelude emission ORDER (Point must precede Line, and both precede Val, which
# carries `line (p1 : Point) (p2 : Point)`), and derive_storable% over struct-typed fields.
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y


class Line:
    def __init__(self, p1: Point, p2: Point):
        self.p1 = p1
        self.p2 = p2
