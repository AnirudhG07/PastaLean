# IO + exceptions + heap + loop: read a batch of readings and accumulate them into a shared Meter
# object. A negative reading raises ValueError, caught per-item (reported as -1) so the loop keeps
# going; the final total is printed at the end.
#   run with input "3\n5\n-2\n7" -> prints  -1  then  12   (5 and 7 counted, -2 rejected)
class Meter:
    def __init__(self):
        self.total = 0
        self.count = 0

    def add(self, x):
        if x < 0:
            raise ValueError("negative reading")
        self.total = self.total + x
        self.count = self.count + 1

    def report(self):
        return self.total


if __name__ == "__main__":
    m = Meter()
    n = int(input())
    i = 0
    while i < n:
        x = int(input())
        try:
            m.add(x)
        except ValueError:
            print(-1)
        i = i + 1
    print(m.report())
