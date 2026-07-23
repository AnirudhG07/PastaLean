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

def maxSubArray(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    # The result is the maximum sum over all contiguous subarrays of nums.
    Ensures(
        Result() == 
        max(
            sum(nums[i:j])
            for i in range(len(nums))
            for j in range(i+1, len(nums)+1)
        )
    )
    ans = f = nums[0]
    for x in nums[1:]:
        # f is the max subarray sum ending at this position so far,
        # ans is the max subarray sum anywhere in the prefix processed so far.
        Invariant(True)
        f = max(f, 0) + x
        ans = max(ans, f)
    return ans