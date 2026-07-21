# A runnable heap program: build and mutate objects through an alias, then print the result.
# `pastalean run` should print 2 (mutation through `b` seen via `a`).
class Counter:
    def __init__(self):
        self.count = 0

    def inc(self):
        self.count = self.count + 1

    def get(self):
        return self.count


if __name__ == "__main__":
    a = Counter()
    b = a
    b.inc()
    b.inc()
    print(a.get())
