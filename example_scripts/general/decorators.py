#!/usr/bin/env python3
"""Decorators — user-defined (nested) wrappers, and the OOP method-binding markers.

A decorator `@d` means `f = d(f)`; stacked decorators apply bottom-up (nearest the `def` first), so
`@a\n@b\ndef f` is `a(b(f))`. Non-transparent user wrappers are lowered by emitting the raw function
and binding the decorated name to the application. Transparent decorators — `@cache` (memoisation is
recompute-equal here) and the class-body markers `@staticmethod`/`@classmethod`/`@property` — leave
the function's value unchanged; the class markers only drop the `self`/`cls` binding.
"""

from functools import cache
from typing import Callable


# User decorators with NO annotation on the wrapped `f`: TypeInfer unifies each decorator's parameter
# with the function it decorates (`inc`, typed `int -> int`), so `f` is inferred `Callable[[int], int]`
# and `f(x)` in the lifted wrapper elaborates — no `Callable` annotation needed.
def double(f):
    def w(x: int) -> int:
        return 2 * f(x)
    return w


def plus_one(f):
    def w(x: int) -> int:
        return f(x) + 1
    return w


# Stacked user decorators: inc(x) = double(plus_one(base))(x) = 2 * ((x+1) + 1).
@double
@plus_one
def inc(x: int) -> int:
    return x + 1


# The reverse direction: the decorator's `Callable` parameter type flows BACK into the decorated
# function, pinning `add`'s otherwise-unknown params to `int` (they would be boxed as PyAny otherwise).
def checked(f: Callable[[int, int], int]) -> Callable[[int, int], int]:
    def w(a: int, b: int) -> int:
        return f(a, b)
    return w


@checked
def add(a, b):
    return a + b


# `@cache`/`@lru_cache`: the RUNNABLE twin memoises (a `StateM`-threaded `HashMap` cache shared across
# the recursion, seeded fresh per top-level call) so exponential DP runs in polynomial time; recursive
# self-calls become `(← fib'memo'rn …)`. The PROVABLE twin `fib` stays the plain pure recursion.
@cache
def fib(n: int) -> int:
    if n < 2:
        return n
    return fib(n - 1) + fib(n - 2)


# OOP: the method-binding markers. `@staticmethod` drops `self`; `@property` reads as an attribute;
# `@classmethod` drops `cls`.
class Vec:
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

    @staticmethod
    def unit() -> int:
        return 1

    @property
    def norm2(self) -> int:
        return self.x * self.x + self.y * self.y

    @classmethod
    def diag(cls, n: int) -> int:
        return n + n


def main():
    print(inc(5))          # 2 * ((5+1)+1) = 14
    print(fib(10))         # 55
    print(add(3, 4))       # 7 — params inferred int from the decorator's Callable signature
    v = Vec(3, 4)
    print(v.norm2)         # 25
    print(Vec.unit())      # 1
    print(Vec.diag(7))     # 14


if __name__ == "__main__":
    main()
