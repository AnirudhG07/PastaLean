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

def singleNonDuplicate(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(Result() in nums)
    l, r = (0, len(nums) - 1)
    while l < r:
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(r < len(nums))
        Decreases(r - l)
        mid = l + r >> 1
        Assert(0 <= mid < len(nums))
        Assert(0 <= (mid ^ 1) < len(nums))
        if nums[mid] != nums[mid ^ 1]:
            r = mid
        else:
            l = mid + 1
    Assert(0 <= l < len(nums))
    return nums[l]