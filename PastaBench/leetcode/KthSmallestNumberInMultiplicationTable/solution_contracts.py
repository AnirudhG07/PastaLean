from contracts import *
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

def findKthNumber(m: int, n: int, k: int) -> int:
    Requires(m > 0)
    Requires(n > 0)
    Requires(1 <= k <= m * n)
    # The returned value L is the k-th smallest entry in the m×n multiplication table:
    # at least k products ≤ L, and fewer than k products ≤ L-1.
    Ensures(sum(min(Result() // i, n) for i in range(1, m + 1)) >= k)
    Ensures(sum(min((Result() - 1) // i, n) for i in range(1, m + 1)) < k)

    left, right = 1, m * n
    # Binary-search invariant: the true answer lies in [left, right].
    # And boundaries stay in [1, m*n].
    # Decrease measure ensures termination.
    while left < right:
        Invariant(1 <= left)
        Invariant(left <= right)
        Invariant(right <= m * n)
        Decreases(right - left)

        mid = (left + right) >> 1
        # mid is at least 1 since left ≥ 1.
        Assert(mid >= 1)

        cnt = 0
        for i in range(1, m + 1):
            # Bound i for safe division and summation.
            Invariant(1 <= i <= m)
            # cnt is nonnegative and accumulates the true count up to i-1.
            Invariant(cnt >= 0)
            cnt += min(mid // i, n)

        # Narrow the search range based on the count at mid.
        if cnt >= k:
            right = mid
        else:
            left = mid + 1

    # At exit left == right and equals the sought k-th value.
    Assert(left == right)
    return left