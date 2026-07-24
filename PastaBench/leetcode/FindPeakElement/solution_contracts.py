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

def findPeakElement(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(0 <= Result() < len(nums))
    Ensures((Result() == 0 or nums[Result()] > nums[Result() - 1]) and
            (Result() == len(nums) - 1 or nums[Result()] > nums[Result() + 1]))
    left, right = 0, len(nums) - 1
    Decreases(right - left)
    while left < right:
        Invariant(0 <= left)
        Invariant(left <= right)
        Invariant(right < len(nums))
        mid = (left + right) >> 1
        if nums[mid] > nums[mid + 1]:
            right = mid
        else:
            left = mid + 1
    # At exit left == right, and that index is a peak
    Assert(left == right)
    Assert((left == 0 or nums[left] > nums[left - 1]) and
           (left == len(nums) - 1 or nums[left] > nums[left + 1]))
    return left