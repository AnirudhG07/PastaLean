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

def maxArrayValue(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    # The maximum value of the array is non-decreasing across the transformation.
    # Therefore, the result must be at least the maximum of the original array.
    # We assume `max(nums)` in the postcondition refers to the state of `nums` at function entry.
    Ensures(Result() >= max(nums))

    for i in range(len(nums) - 2, -1, -1):
        # Invariants to ensure memory safety for the accesses nums[i] and nums[i+1].
        # The loop iterates i from len(nums) - 2 down to 0.
        Invariant(0 <= i < len(nums))
        Invariant(0 <= i + 1 < len(nums))

        if nums[i] <= nums[i + 1]:
            nums[i] += nums[i + 1]
            
    return max(nums)