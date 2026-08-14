import heapq
import itertools
from sortedcontainers import SortedList
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

def continuousSubarrays(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    # The number of continuous subarrays is bounded by the total number of subarrays.
    Ensures(Result() <= len(nums) * (len(nums) + 1) // 2)
    ans = i = 0
    sl = SortedList()
    for x in nums:
        sl.add(x)
        while sl[-1] - sl[0] > 2:
            Invariant(0 <= i)
            Invariant(i <= len(nums))
            # `i` increases in each iteration, so `len(nums) - i` strictly decreases
            # and is bounded below by 0, ensuring termination.
            Decreases(len(nums) - i)

            # The index `i` tracks the start of the sliding window. The window's
            # end corresponds to the current element from `nums`. Thus, `i` must
            # be a valid index for `nums` when `nums[i]` is accessed.
            Assert(i < len(nums))
            sl.remove(nums[i])
            i += 1
        
        # The point of the `while` loop is to shrink the window from the left (by advancing `i`)
        # until its elements `sl` satisfy `max(sl) - min(sl) <= 2`.
        # The list `sl` is guaranteed to be non-empty at this point.
        Assert(len(sl) > 0)
        Assert(sl[-1] - sl[0] <= 2)
        ans += len(sl)
    return ans