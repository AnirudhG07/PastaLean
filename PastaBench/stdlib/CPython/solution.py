"""Algorithms taken from CPython's standard library.

    gcd                          Lib/fractions.py  (Euclid; the algorithm behind math.gcd)
    bisect_left, bisect_right    Lib/bisect.py
    mean, median                 Lib/statistics.py

Only the algorithm is kept. The `lo`/`hi` bounds arguments, the `key=` keyword and the input
validation that raises are dropped; type annotations are added.
"""


def gcd(a: int, b: int) -> int:
    while b:
        a, b = b, a % b
    return a


def bisect_left(a: list[int], x: int) -> int:
    lo = 0
    hi = len(a)
    while lo < hi:
        mid = (lo + hi) // 2
        if a[mid] < x:
            lo = mid + 1
        else:
            hi = mid
    return lo


def bisect_right(a: list[int], x: int) -> int:
    lo = 0
    hi = len(a)
    while lo < hi:
        mid = (lo + hi) // 2
        if x < a[mid]:
            hi = mid
        else:
            lo = mid + 1
    return lo


def mean(data: list[int]) -> float:
    return sum(data) / len(data)


def median(data: list[int]) -> float:
    data = sorted(data)
    n = len(data)
    if n % 2 == 1:
        return data[n // 2]
    else:
        i = n // 2
        return (data[i - 1] + data[i]) / 2
