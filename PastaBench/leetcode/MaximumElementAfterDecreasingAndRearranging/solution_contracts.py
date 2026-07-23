from contracts import *
from typing import List

def maximumElementAfterDecrementingAndRearranging(arr: List[int]) -> int:
    Requires(len(arr) > 0)
    arr.sort()
    arr[0] = 1
    for i in range(1, len(arr)):
        Invariant(1 <= i)
        Invariant(i < len(arr))
        d = max(0, arr[i] - arr[i - 1] - 1)
        arr[i] -= d
    return max(arr)