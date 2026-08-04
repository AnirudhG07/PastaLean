# __init__ with parameters -> C.new takes arguments; fields typed from the assigned params.
# Exercises: multi-field struct, constructor-with-args, Val ctor field ordering.
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def sum(self):
        return self.x + self.y
