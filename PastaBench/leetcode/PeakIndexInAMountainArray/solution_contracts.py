import random
import functools
import collections
import string
import math
import datetime
from typing import *
from functools import *
from collections import *
from itertools import *
from heapq import *
from bisect import *
from string import *
from operator import *
from math import *
from contracts import *


def peakIndexInMountainArray(arr: List[int]) -> int:
    Requires(len(arr) >= 3)
    # arr is a mountain: strictly increases then strictly decreases
    Requires(any(
        0 < p < len(arr) - 1
        and all(arr[i] < arr[i + 1] for i in range(p))
        and all(arr[i] > arr[i + 1] for i in range(p, len(arr) - 1))
        for p in range(len(arr))
    ))
    Ensures(0 < Result() < len(arr) - 1)
    Ensures(arr[Result()] > arr[Result() - 1])
    Ensures(arr[Result()] > arr[Result() + 1])
    left, right = (1, len(arr) - 2)
    while left < right:
        Invariant(1 <= left)
        Invariant(left < right)
        Invariant(right <= len(arr) - 2)
        # the true peak index stays in [left, right]
        Invariant(any(
            left <= k <= right
            and arr[k] > arr[k - 1]
            and arr[k] > arr[k + 1]
            for k in range(len(arr))
        ))
        Decreases(right - left)
        mid = left + right >> 1
        if arr[mid] > arr[mid + 1]:
            right = mid
        else:
            left = mid + 1
    # at exit left == right and it must be the peak
    Assert(arr[left] > arr[left - 1] and arr[left] > arr[left + 1])
    return left