# Passing a mutable CONTAINER across a function boundary (--heap). Under reference semantics a
# `list`/`dict`/`set` parameter is the object-ref itself (`Ref (List Int)`), so the function joins the
# heap tier (`HeapM Val`) and its callers await it. Every consumption inside the callee dereferences
# the ref: `len`/subscript/iteration read it, `.append` mutates it in place (visible to the caller).
# Boundary cases: a pure reader, a returns-None mutator, multiple container params, transitive passing
# (a container param handed to another container-param function), and a shared list mutated then re-read.
def total(xs: list[int]) -> int:
    s = 0
    for v in xs:
        s += v
    return s


def first(xs: list[int]) -> int:
    return xs[0]


def push_twice(xs: list[int], v: int) -> None:  # returns-None mutator through the ref
    xs.append(v)
    xs.append(v)


def extend_with(dst: list[int], src: list[int]) -> None:  # two container params
    for v in src:
        dst.append(v)


def grow_then_total(xs: list[int], v: int) -> int:  # transitive: hands `xs` to another ref-taker
    push_twice(xs, v)
    return total(xs)


if __name__ == "__main__":
    ys = [1, 2, 3]
    push_twice(ys, 10)
    print(total(ys))  # 1+2+3+10+10 == 26
    print(first(ys))  # 1
    print(len(ys))  # 5

    more = [100, 200]
    extend_with(ys, more)
    print(len(ys))  # 7
    print(total(ys))  # 26 + 300 == 326

    print(grow_then_total(ys, 1))  # appends 1,1 then totals: 326 + 2 == 328
    print(len(ys))  # 9
