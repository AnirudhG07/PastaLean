#!/usr/bin/env python3
"""Class fields whose type comes from what `__init__` assigns, plus self-recursive methods.

An unannotated field used to fall back to `Int` unless its initialiser was a bare literal, so
`self.p = list(range(n))` produced `p : Int` and every later `self.p[x]` failed to resolve. A method
that calls itself (path compression) also has no termination proof, so it must be emitted `partial`.
"""

from typing import List


class UnionFind:
    def __init__(self, n):
        self.p = list(range(n))          # a Call initialiser — not a literal shape
        self.size = [1] * n
        self.count = n

    def find(self, x):                   # self-recursive: needs `partial`
        if self.p[x] != x:
            self.p[x] = self.find(self.p[x])
        return self.p[x]

    def union(self, a, b):
        ra, rb = self.find(a), self.find(b)
        if ra != rb:
            self.p[ra] = rb
            self.count -= 1


class Bag:
    def __init__(self, words: List[str]):
        self.words = sorted(words)       # Call initialiser → list[str], not Int
        self.n = len(words)

    def first(self) -> str:
        return self.words[0]


def main():
    uf = UnionFind(6)
    uf.union(0, 1)
    uf.union(1, 2)
    print(uf.find(0) == uf.find(2))
    print(uf.find(0) == uf.find(5))
    b = Bag(["pear", "apple"])
    print(b.first())
    print(b.n)


if __name__ == "__main__":
    main()
