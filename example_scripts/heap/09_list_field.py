# A class holding a mutable list, grown and measured through methods.
# Exercises containers-as-refs: the `items` field is a `Ref (List Int)`, `[]` allocates a heap list,
# `.append` mutates it through the ref, and `len` reads through it.
class Bag:
    def __init__(self):
        self.items = []

    def add(self, x):
        self.items.append(x)

    def size(self):
        return len(self.items)


def demo():
    b = Bag()
    b.add(10)
    b.add(20)
    b.add(30)
    return b.size()
