# Container reads/writes beyond append: indexing (read + write) and iteration, all through a
# heap-allocated list field. Returns 149.
class IntList:
    def __init__(self):
        self.data = []

    def push(self, x):
        self.data.append(x)

    def get(self, i):
        return self.data[i]

    def set(self, i, x):
        self.data[i] = x

    def total(self):
        s = 0
        for v in self.data:
            s = s + v
        return s


def demo():
    xs = IntList()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    xs.set(1, 99)                  # data = [10, 99, 30]
    return xs.total() + xs.get(0)  # 139 + 10
