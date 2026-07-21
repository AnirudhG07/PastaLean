# Simplest case: one Int field + a getter method.
# Exercises: struct with a single primitive field, `Val.counter (count : Int)`,
# derive_storable% on a trivial class, value-mode C.new (record literal) coexisting with the prelude.
class Counter:
    def __init__(self):
        self.count = 0

    def value(self):
        return self.count
