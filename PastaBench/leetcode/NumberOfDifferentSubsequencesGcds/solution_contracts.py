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

def countDifferentSubsequenceGCDs(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Requires(all(n > 0 for n in nums))
    # The result is the number of distinct GCDs, which must be non-negative.
    Ensures(Result() >= 0)
    # Any possible GCD of a subsequence must be less than or equal to the maximum element in the list.
    # Therefore, the count of such distinct GCDs cannot exceed this maximum value.
    Ensures(Result() <= max(nums))

    mx = max(nums)
    Assert(mx > 0)
    vis = set(nums)
    ans = 0
    # Outer loop iterates through all potential GCD values `x` from 1 up to `mx`.
    for x in range(1, mx + 1):
        Invariant(1 <= x <= mx + 1)
        # `ans` counts the number of valid GCDs found in the range `[1, x-1]`.
        # So, `ans` is always less than the current candidate `x`.
        Invariant(0 <= ans < x)

        g = 0
        # Inner loop calculates the GCD of all numbers in `nums` that are multiples of `x`.
        # If this GCD equals `x`, then `x` is a possible subsequence GCD.
        for y in range(x, mx + 1, x):
            Invariant(x <= y <= mx)
            Invariant(y % x == 0)
            # The running GCD `g` is either 0 (initially) or a multiple of `x`,
            # since it's computed from numbers `y` that are all multiples of `x`.
            Invariant(g == 0 or (g > 0 and g % x == 0))
            Invariant(0 <= g <= mx)

            if y in vis:
                g = gcd(g, y)
                if g == x:
                    # Found a subsequence (multiples of x in nums) whose GCD is x.
                    # This is an optimization: once g reaches x, it can't get smaller while
                    # remaining a multiple of x, so gcd of all multiples of x must be x.
                    ans += 1
                    break
    
    Assert(0 <= ans <= mx)
    return ans