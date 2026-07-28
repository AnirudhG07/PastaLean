#!/usr/bin/env python3
"""Methods that return a value AND mutate the receiver.

The subtle one is `pop`: arity alone decides the container. `xs.pop(i)` indexes a list, while
`d.pop(k, default)` is a *dict* pop whose second argument is a default, not an index — so the two
lower to different runtime pairs. `setdefault` is the same value+mutate shape.
"""

from typing import List


# 2-arg pop is a DICT pop (key, default) — not a list pop with an index.
def take(counts: dict, key: int) -> int:
    hit = counts.pop(key, -1)
    miss = counts.pop(999999, -1)
    return hit + miss


# 0-/1-arg pop is a LIST pop (optional index), value + shortened list.
def drain(xs: List[int]) -> int:
    last = xs.pop()
    first = xs.pop(0)
    return last + first


# `setdefault` returns d[k]-or-default and inserts only when the key is absent.
def tally(nums: List[int]) -> int:
    d = {}
    for n in nums:
        seen = d.setdefault(n, 0)
        d[n] = seen + 1
    return len(d)


def main():
    print(take({1: 10, 2: 20}, 1))
    print(drain([3, 4, 5]))
    print(tally([1, 1, 2]))


if __name__ == "__main__":
    main()
