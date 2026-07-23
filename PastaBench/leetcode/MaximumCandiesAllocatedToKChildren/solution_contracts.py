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

def maximumCandies(candies: List[int], k: int) -> int:
    Requires(k > 0)
    Requires(len(candies) > 0)
    Requires(all(c >= 0 for c in candies))
    Ensures(0 <= Result())
    Ensures(Result() <= max(candies))
    # result is the largest size m such that sum(c // m) >= k
    Ensures((Result() == 0) or sum(c // Result() for c in candies) >= k)
    Ensures(sum(c // (Result() + 1) for c in candies) < k)
    l, r = 0, max(candies)
    while l < r:
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(r <= max(candies))
        Invariant((l == 0) or sum(c // l for c in candies) >= k)
        Invariant(sum(c // (r + 1) for c in candies) < k)
        Decreases(r - l)
        mid = (l + r + 1) >> 1
        if sum(x // mid for x in candies) >= k:
            l = mid
        else:
            r = mid - 1
    # at exit l == r, so these capture feasibility and maximality
    Assert((l == 0) or sum(c // l for c in candies) >= k)
    Assert(sum(c // (l + 1) for c in candies) < k)
    return l