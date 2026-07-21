# A generic Stack that holds values of ANY type. Because `list[object]` can't be pinned to a single
# concrete element type, PastaLean applies its gradual-typing fallback and boxes the element to
# `PyAny` -- so the SAME stack holds an int, a str, and a bool at once. Each value is auto-boxed on
# `push` and unboxed (via tag dispatch) on read. The stack lives on the heap (`Ref (List PyAny)`), so
# it also has real reference semantics.
#   pastalean run --heap  ->  prints  3  then  42  then  hello  then  True  then  True
class Stack:
    def __init__(self):
        self.items: list[object] = []

    def push(self, x: object):
        self.items.append(x)

    def get(self, i: int):
        return self.items[i]

    def peek(self):
        return self.items[len(self.items) - 1]

    def is_empty(self):
        return len(self.items) == 0

    def size(self):
        return len(self.items)


if __name__ == "__main__":
    s = Stack()
    s.push(42)        # int
    s.push("hello")   # str
    s.push(True)      # bool
    print(s.size())   # 3 -- one stack, three different element types
    print(s.get(0))   # 42
    print(s.get(1))   # hello
    print(s.get(2))   # True
    print(s.peek())   # True (top of stack)
