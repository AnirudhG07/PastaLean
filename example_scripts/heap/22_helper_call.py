# A heap free-function (`total`) called from another function / `__main__`. The call must be awaited
# (it returns a `HeapM` action). `pastalean run` should print 2.
class Counter:
    def __init__(self):
        self.count = 0

    def inc(self):
        self.count = self.count + 1

    def get(self):
        return self.count


def total():
    a = Counter()
    a.inc()
    a.inc()
    return a.get()


if __name__ == "__main__":
    result = total()
    print(result)
