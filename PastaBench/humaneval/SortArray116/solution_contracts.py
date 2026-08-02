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
    Ensures(len(Result()) == len(arr))
    Ensures(sorted(Result()) == sorted(arr))

    from functools import cmp_to_key
    def cmp(x: int, y: int) -> int:
        Ensures((x1 > y1 and Result() > 0) or
                (x1 < y1 and Result() < 0) or
                (x1 == y1 and Result() == x - y))

        x1 = len(list(filter(lambda ch: ch == "1", bin(x))))
        y1 = len(list(filter(lambda ch: ch == "1", bin(y))))

        Assert(x1 >= 0)
        Assert(y1 >= 0)
        
        if x1 != y1: return x1 - y1
        return x - y
    return sorted(arr, key=cmp_to_key(cmp))