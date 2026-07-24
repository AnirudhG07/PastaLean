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


def validSubarrays(nums: List[int]) -> int:
    # no precondition needed; empty list yields 0
    right = [len(nums)] * len(nums)
    stk: List[int] = []
    for i in range(len(nums) - 1, -1, -1):
        Invariant(0 <= i)
        Invariant(i < len(nums))
        # maintain that every index popped or peeked is in range
        while stk and nums[stk[-1]] >= nums[i]:
            Assert(0 <= stk[-1] < len(nums))
            stk.pop()
        if stk:
            Assert(0 <= stk[-1] < len(nums))
            right[i] = stk[-1]
            # ensures the "next smaller to the right" index is strictly greater than i
            Assert(i < right[i] <= len(nums))
        stk.append(i)
    result = sum(j - i for i, j in enumerate(right))
    Ensures(Result() >= 0)
    return result