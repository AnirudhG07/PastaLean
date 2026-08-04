# Single inheritance (subclass extends base).
# Exercises: `structure Derived extends Base` in the prelude AND the interaction with the generated
# `Val` constructor / derive_storable% (whether the Val ctor's fields line up with the flattened
# structure fields is a known sharp edge at this stage).
class Base:
    def __init__(self, x):
        self.x = x


class Derived(Base):
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def total(self):
        return self.x + self.y
