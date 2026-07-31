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

def searchInsert(nums: List[int], target: int) -> int:
    Requires(all(nums[i] <= nums[i+1] for i in range(len(nums) - 1)))

    Ensures(0 <= Result() <= len(nums))
    Ensures(all(x < target for x in nums[:Result()]))
    Ensures(all(x >= target for x in nums[Result():]))

    l, r = (0, len(nums))
    while l < r:
        Invariant(0 <= l <= r <= len(nums))
        Invariant(all(x < target for x in nums[:l]))
        Invariant(all(x >= target for x in nums[r:]))
        Decreases(r - l)

        mid = l + r >> 1
        Assert(0 <= mid < len(nums))
        if nums[mid] >= target:
            r = mid
        else:
            l = mid + 1

    Assert(0 <= l <= len(nums))
    Assert(all(x < target for x in nums[:l]))
    Assert(all(x >= target for x in nums[l:]))
    return l