# IO + exceptions + heap containers: an event Log with a list field and a capacity. Two handles
# (`log`, `mirror`) share the same object, so appends through one are seen through the other. Adding
# past capacity raises ValueError, caught and reported as -1. Reads the capacity from input.
#   run with input "5" -> prints 3 (all three adds fit)
#   run with input "2" -> prints -1 (the third add overflows)
class Log:
    def __init__(self, capacity):
        self.capacity = capacity
        self.events = []

    def add(self, e):
        if len(self.events) >= self.capacity:
            raise ValueError("log full")
        self.events.append(e)

    def size(self):
        return len(self.events)


if __name__ == "__main__":
    cap = int(input())
    log = Log(cap)
    mirror = log
    try:
        log.add(10)
        mirror.add(20)
        log.add(30)
        print(mirror.size())
    except ValueError:
        print(-1)
