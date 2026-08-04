# Container reference semantics through a shared object: two handles to the same Bag share the same
# underlying heap list, so appends through either are visible via the other. Returns 3.
class Bag:
    def __init__(self):
        self.items = []

    def add(self, x):
        self.items.append(x)

    def size(self):
        return len(self.items)


def demo():
    a = Bag()
    b = a           # same Bag → the SAME items list
    a.add(1)
    b.add(2)
    b.add(3)
    return a.size()
