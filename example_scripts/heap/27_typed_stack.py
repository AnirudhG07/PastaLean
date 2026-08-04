# A generic Stack specialized to ONE element type -- like Java's Stack<String>. The element type is
# fixed by the annotation `list[str]`, so PastaLean monomorphizes the whole class to a homogeneous
# `Ref (List String)` (change the annotation to `list[int]` and the exact same class source becomes a
# Stack<Integer> -> `Ref (List Int)`). Contrast 26_generic_stack.py, whose `list[object]` makes a
# heterogeneous `Ref (List PyAny)`; here every element has the one declared type.
#   pastalean run --heap  ->  prints  2  then  world  then  hello
class Stack:
    def __init__(self):
        self.items: list[str] = []

    def push(self, x: str):
        self.items.append(x)

    def peek(self) -> str:
        return self.items[len(self.items) - 1]

    def get(self, i: int) -> str:
        return self.items[i]

    def size(self) -> int:
        return len(self.items)


if __name__ == "__main__":
    s = Stack()
    s.push("hello")
    s.push("world")
    print(s.size())   # 2
    print(s.peek())   # world  (top of stack)
    print(s.get(0))   # hello
