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

def maximumBeauty(nums: List[int], k: int) -> int:
    Requires(len(nums) > 0)
    Requires(k >= 0)
    Requires(all(x >= 0 for x in nums))
    Ensures(1 <= Result() <= len(nums))

    m = max(nums) + k * 2 + 2
    d = [0] * m
    for x in nums:
        # This loop populates a difference array `d`. For each number `x` in `nums`,
        # it marks the start of an interval of influence at `x` and the end at `x + 2*k`.
        # The invariant is that the sum of differences is always zero, as each `+1`
        # is paired with a `-1`.
        Invariant(sum(d) == 0)
        d[x] += 1
        d[x + k * 2 + 1] -= 1

    # The maximum prefix sum of the difference array `d` gives the maximum number of
    # overlapping intervals. This value corresponds to the maximum number of elements
    # from `nums` that can fall within any window of size `2*k`, which is the
    # definition of the problem's "beauty".
    res = max(accumulate(d))

    Assert(res <= len(nums))
    Assert(res >= 1)
    return res