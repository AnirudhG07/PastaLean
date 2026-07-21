# Operator/print dunders become typeclass instances alongside the prelude.
# Exercises: __add__ -> PyHAdd, __eq__ -> BEq (so the struct does NOT derive BEq), __str__ ->
# PyPrintable, all referencing the prelude-emitted structure.
class Vec:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def __add__(self, other):
        return Vec(self.x + other.x, self.y + other.y)

    def __eq__(self, other):
        return self.x == other.x and self.y == other.y

    def __str__(self):
        return "vec"
