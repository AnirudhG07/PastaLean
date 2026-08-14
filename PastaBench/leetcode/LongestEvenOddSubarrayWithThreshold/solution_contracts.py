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

def longestAlternatingSubarray(nums: List[int], threshold: int) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(nums))

    ans, n = (0, len(nums))
    for l in range(n):
        Invariant(0 <= l <= n)
        Invariant(0 <= ans <= n)

        if nums[l] % 2 == 0 and nums[l] <= threshold:
            Assert(nums[l] % 2 == 0 and nums[l] <= threshold)
            r = l + 1
            while r < n and nums[r] % 2 != nums[r - 1] % 2 and (nums[r] <= threshold):
                # These bounds are crucial for proving memory safety of nums[r] and nums[r-1].
                Invariant(l < r)
                Invariant(r <= n)
                # The termination measure is the distance from r to the end of the array.
                Decreases(n - r)
                r += 1
            # After the inner loop, nums[l:r] is the longest valid subarray starting at l.
            Assert(l < r <= n)
            ans = max(ans, r - l)
    return ans