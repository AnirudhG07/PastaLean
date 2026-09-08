from itertools import accumulate
from operator import xor, mul
from typing import List


# `accumulate(xs, f)` and `accumulate(xs, f, initial=v)` must fold with the given binary op,
# not silently fall back to summation. Regression for xor-queries-of-a-subarray.
def prefix_xor(arr: List[int]) -> List[int]:
    return list(accumulate(arr, xor, initial=0))


def running_product(arr: List[int]) -> List[int]:
    return list(accumulate(arr, mul))


def xor_range_queries(arr: List[int], queries: List[List[int]]) -> List[int]:
    s = list(accumulate(arr, xor, initial=0))
    return [s[r + 1] ^ s[l] for l, r in queries]
