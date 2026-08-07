from typing import *
from contracts import *


def sort_array(arr: List[int]):
    """
    In this Kata, you have to sort an array of non-negative integers according to
    number of ones in their binary representation in ascending order.
    For similar number of ones, sort based on decimal value.

    It must be implemented like this:
    >>> sort_array([1, 5, 2, 3, 4]) == [1, 2, 3, 4, 5]
    >>> sort_array([-2, -3, -4, -5, -6]) == [-6, -5, -4, -3, -2]
    >>> sort_array([1, 0, 2, 3, 4]) [0, 1, 2, 3, 4]
    """
    # 1-2. The result is a permutation of the input (same length, same multiset).
    Ensures(len(Result()) == len(arr))
    Ensures(sorted(Result()) == sorted(arr))
    # 3. The result is ordered by the key (popcount, value): consecutive entries either strictly
    #    increase in the number of binary ones, or tie there and then increase in decimal value.
    Ensures(all(
        bin(Result()[j]).count("1") < bin(Result()[j + 1]).count("1")
        or (bin(Result()[j]).count("1") == bin(Result()[j + 1]).count("1")
            and Result()[j] <= Result()[j + 1])
        for j in range(len(Result()) - 1)))

    from functools import cmp_to_key
    def cmp(x: int, y: int) -> int:
        x1 = len(list(filter(lambda ch: ch == "1", bin(x))))
        y1 = len(list(filter(lambda ch: ch == "1", bin(y))))

        # Bridge the filter/len popcount to the `bin(...).count("1")` form the Ensures speaks in.
        Assert(x1 == bin(x).count("1"))
        Assert(y1 == bin(y).count("1"))
        Assert(x1 >= 0 and y1 >= 0)

        if x1 != y1: return x1 - y1
        return x - y
    return sorted(arr, key=cmp_to_key(cmp))