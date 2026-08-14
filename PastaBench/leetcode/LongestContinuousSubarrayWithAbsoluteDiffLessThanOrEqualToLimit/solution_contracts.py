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

def longestSubarray(nums: List[int], limit: int) -> int:
    Requires(limit >= 0)
    Ensures(0 <= Result() <= len(nums))
    Ensures(len(nums) == 0 or Result() >= 1)

    sl = SortedList()
    ans = j = 0
    for i, x in enumerate(nums):
        Invariant(0 <= i <= len(nums))
        Invariant(0 <= j <= i)
        Invariant(ans >= 0)
        Invariant(ans <= i)
        Invariant(len(sl) == i - j)
        # The window `nums[j:i]` represented by `sl` is valid.
        # If i == j, sl is empty. Otherwise, sl is non-empty.
        Invariant(i == j or sl[-1] - sl[0] <= limit)

        sl.add(x)
        # Now sl represents elements of nums[j:i+1]

        while sl[-1] - sl[0] > limit:
            # Loop is only entered if len(sl) >= 2, since if len(sl)==1, max-min=0 <= limit.
            Invariant(len(sl) >= 2)
            Invariant(0 <= j < i)
            # This quantity is constant through the while loop.
            Invariant(len(sl) + j == i + 1)
            Decreases(i - j)

            sl.remove(nums[j])
            j += 1

        # After the while loop, the window `nums[j:i+1]` is valid.
        # `sl` cannot be empty because `x=nums[i]` was added and is not removed (since j<=i)
        Assert(len(sl) >= 1)
        Assert(sl[-1] - sl[0] <= limit)
        Assert(len(sl) + j == i + 1)

        ans = max(ans, i - j + 1)
        Assert(ans >= i - j + 1)
    return ans