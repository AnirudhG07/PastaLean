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

def findMin(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(Result() == min(nums))
    left, right = (0, len(nums) - 1)
    while left < right:
        Invariant(0 <= left)
        Invariant(left <= right)
        Invariant(right < len(nums))
        Invariant(min(nums[left:right+1]) == min(nums))
        Decreases(right - left)
        mid = left + right >> 1
        if nums[mid] > nums[right]:
            left = mid + 1
        elif nums[mid] < nums[right]:
            right = mid
        else:
            right -= 1
    Assert(nums[left] == min(nums))
    return nums[left]