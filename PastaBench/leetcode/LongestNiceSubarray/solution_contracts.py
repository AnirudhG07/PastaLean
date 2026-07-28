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

def longestNiceSubarray(nums: List[int]) -> int:
    Ensures(0 <= Result())
    Ensures(Result() <= len(nums))
    ans = mask = l = 0
    for r, x in enumerate(nums):
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(mask == reduce(or_, nums[l:r], 0))
        while mask & x:
            Invariant(0 <= l)
            Invariant(l <= r)
            Invariant(mask == reduce(or_, nums[l:r], 0))
            Decreases(r - l)
            mask ^= nums[l]
            l += 1
        Assert(mask & x == 0)
        mask |= x
        Assert(mask == reduce(or_, nums[l:r+1], 0))
        ans = max(ans, r - l + 1)
    return ans