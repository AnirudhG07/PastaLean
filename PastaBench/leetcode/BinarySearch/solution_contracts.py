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

def search(nums: List[int], target: int) -> int:
    """
    Finds the first index of `target` in a sorted list `nums`.
    This is a binary search variant that finds the leftmost match.
    The algorithm assumes `nums` is sorted in non-decreasing order.
    """
    Requires(len(nums) > 0)
    Ensures(Result() == -1 or (0 <= Result() < len(nums) and nums[Result()] == target))

    l, r = (0, len(nums) - 1)
    while l < r:
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(r < len(nums))
        Decreases(r - l)

        mid = l + r >> 1
        Assert(l <= mid < r)

        if nums[mid] >= target:
            r = mid
        else:
            l = mid + 1
    
    Assert(l == r)
    Assert(0 <= l < len(nums))

    return l if nums[l] == target else -1