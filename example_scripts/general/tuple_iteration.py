#!/usr/bin/env python3
"""Iterating and consuming n-tuples.

A Python tuple is immutable and stays a tuple (a nested Lean product `a × (b × …)`), NOT a list. But
a *homogeneous* tuple is still a sequence: it can be iterated, paired up, summed. That works through a
recursive `PyIterable (α × β) α` instance that flattens an all-`α` tuple to a `List α` at the point of
iteration — the tuple itself is never rewritten to a list.
"""

from itertools import pairwise


# The classic direction-deltas idiom: a fixed tuple iterated via `pairwise`.
def neighbours(i: int, j: int):
    dirs = (-1, 0, 1, 0, -1)
    out = []
    for a, b in pairwise(dirs):
        out.append((i + a, j + b))
    return out


# A homogeneous tuple consumed by `sum` / `max` and iterated by a `for`.
def stats(t):
    total = 0
    for x in t:
        total += x
    return total, max(t), min(t)


# A homogeneous tuple is indexable (`t[k]`) and sliceable (`t[1:]`, `t[:]`) — a variable-length
# slice flattens to a list, since it can't stay a fixed-arity product.
def homog_index():
    t = (3, 1, 4, 1, 5)
    return t[0], t[2], t[1:], t[:]


# A heterogeneous tuple keeps a distinct type per slot; a constant index projects the exact one.
def heterog_index():
    t = (1, "a", 3)
    return t[0], t[1], t[2]


# Nested for-target: `(a, b)` comes from `zip` (a Prod), so it must unpack via Prod, not list index.
def nested_for_unpack(xs, ys):
    total = 0
    for i, (a, b) in enumerate(zip(xs, ys), 1):
        total += i * (a + b)
    return total


def main():
    print(neighbours(5, 5))                 # [(4,5),(5,6),(6,5),(5,4)]
    print(nested_for_unpack([1, 2], [3, 4]))  # 1*(1+3) + 2*(2+4) = 16
    print(stats((3, 1, 4, 1, 5, 9, 2)))     # (25, 9, 1)
    print(homog_index())                    # (3, 4, [1, 4, 1, 5], [3, 1, 4, 1, 5])
    print(heterog_index())                  # (1, a, 3)


if __name__ == "__main__":
    main()
