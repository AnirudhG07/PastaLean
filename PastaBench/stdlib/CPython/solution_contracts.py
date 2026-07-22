"""`solution.py` annotated with contracts and reshaped for the verified `while` track.

The algorithms are unchanged. Three rewrites are forced by `pyWhile`, which accepts a loop body
of straight-line assignments to bare names only:

    a, b = b, a % b        ->  unrolled through a temporary
    if ...: lo = mid + 1   ->  ternary assignment
    parameters as loop state -> copied into locals, every loop variable initialised before the loop
"""
from contracts import *


def gcd(a: int, b: int) -> int:
    Requires(a >= 0)
    Requires(b >= 0)
    Ensures(Result() >= 0)
    x = a
    y = b
    t = 0
    while y != 0:
        Invariant(x >= 0)
        Invariant(y >= 0)
        Decreases(y)
        t = x % y
        x = y
        y = t
    return x


def bisect_left(a: list[int], x: int) -> int:
    Requires(len(a) >= 0)
    Ensures(Result() >= 0)
    lo = 0
    hi = len(a)
    mid = 0
    while lo < hi:
        Invariant(lo >= 0)
        Invariant(lo <= hi)
        Decreases(hi - lo)
        mid = (lo + hi) // 2
        lo = mid + 1 if a[mid] < x else lo
        hi = hi if a[mid] < x else mid
    return lo


def bisect_right(a: list[int], x: int) -> int:
    Requires(len(a) >= 0)
    Ensures(Result() >= 0)
    lo = 0
    hi = len(a)
    mid = 0
    while lo < hi:
        Invariant(lo >= 0)
        Invariant(lo <= hi)
        Decreases(hi - lo)
        mid = (lo + hi) // 2
        hi = mid if x < a[mid] else hi
        lo = lo if x < a[mid] else mid + 1
    return lo


def mean(data: list[int]) -> float:
    Requires(len(data) > 0)
    Ensures(Result() * len(data) == sum(data))
    return sum(data) / len(data)


def median(data: list[int]) -> float:
    Requires(len(data) > 0)
    Ensures(Result() * 2 == sum(sorted(data)[len(data) // 2 - 1:len(data) // 2 + 1]) if len(data) % 2 == 0 else sorted(data)[len(data) // 2])
    s = sorted(data)
    n = len(s)
    return s[n // 2] if n % 2 == 1 else (s[n // 2 - 1] + s[n // 2]) / 2
