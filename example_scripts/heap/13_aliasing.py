# Real reference semantics: `b = a` aliases the SAME object, so a mutation through `b` is visible
# through `a`. Under value semantics this returns 0; with --heap it returns 2.
class Counter:
    def __init__(self):
        self.count = 0

    def inc(self):
        self.count = self.count + 1

    def get(self):
        return self.count


def demo():
    a = Counter()
    b = a
    b.inc()
    b.inc()
    return a.get()
