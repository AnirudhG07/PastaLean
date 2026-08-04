# Passing a user OBJECT across a function boundary (--heap). Under reference semantics an object
# parameter is `Ref C`, so a free function can mutate the caller's object in place. Field READS
# dereference (`(← c ~> n)`); field WRITES lower to the pointer write `c ~> attr <~ v` — both the plain
# assign `c.n = v` and the aug-assign `c.n += k` (which reads-then-writes through the ref). The function
# joins the heap tier and callers await it. Boundary cases: aug-write, plain write, a pure reader, two
# object params, and mutation observed both via a reader and by direct field access on the caller's ref.
class Counter:
    def __init__(self, n: int) -> None:
        self.n = n


def bump(c: Counter, k: int) -> None:  # aug-write through the ref
    c.n += k


def reset(c: Counter, v: int) -> None:  # plain write through the ref
    c.n = v


def value_of(c: Counter) -> int:  # pure field read
    return c.n


def move(dst: Counter, src: Counter) -> None:  # two object params: copy one field into another
    dst.n = src.n


if __name__ == "__main__":
    c = Counter(5)
    bump(c, 10)
    print(value_of(c))  # 15
    print(c.n)  # 15 (mutation visible on the caller's ref)

    reset(c, 3)
    print(c.n)  # 3

    d = Counter(99)
    move(c, d)
    print(c.n)  # 99
    print(d.n)  # 99 (source unchanged)
