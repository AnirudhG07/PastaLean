#!/usr/bin/env python3
"""Iterators with no finite `List` behind them, plus in-place `bisect` insertion.

`count`/`cycle`/`repeat(x)` never end, so there is nothing for `pyIter` to return; each is unrolled
into a `while True` whose body ADVANCES FIRST. Advancing at the top is what `skips` pins down: with a
trailing bump a `continue` would jump over it and the loop would never terminate.
"""

from bisect import insort, insort_left
from itertools import count, cycle, repeat


# `continue` must still advance the counter, and a non-unit step must survive the unroll.
def skips(n: int) -> int:
    total = 0
    for k in count(0, 2):
        if k > n:
            break
        if k % 3 == 0:
            continue
        total += k
    return total


# `cycle` re-reads its source forever; `break` is the only exit.
def cyc(xs, n: int):
    out = []
    i = 0
    for c in cycle(xs):
        if i >= n:
            break
        out.append(c)
        i += 1
    return out


# `repeat(x)` is unbounded, but `repeat(x, n)` is finite and keeps the ordinary lowering.
def rep(n: int) -> int:
    s = 0
    i = 0
    for v in repeat(7):
        if i >= n:
            break
        s += v
        i += 1
    return s + sum(repeat(1, 3))


# `insort` mutates its list argument in place and returns None.
def sorted_insert(xs):
    a = []
    for x in xs:
        insort(a, x)
    insort_left(a, 3)
    return a


def main():
    print(skips(10))
    print(cyc([1, 2, 3], 7))
    print(rep(4))
    print(sorted_insert([3, 1, 2]))


if __name__ == "__main__":
    main()
