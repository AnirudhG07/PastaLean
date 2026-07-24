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

def maximizeGreatness(nums: List[int]) -> int:
    nums.sort()
    # Domain fact: after sort, list is non-decreasing
    Assume(all(nums[k] <= nums[k+1] for k in range(len(nums)-1)))
    i = 0
    for x in nums:
        Invariant(0 <= i)
        Invariant(i < len(nums))
        # each time x > nums[i], we match x to beat nums[i] and increment i
        i += x > nums[i]
    return i