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

def minOperations(nums: List[int], numsDivide: List[int]) -> int:
    Requires(len(numsDivide) > 0)
    Requires(all(v > 0 for v in numsDivide))
    Requires(all(v > 0 for v in nums))
    Ensures(Result() == -1 or (0 <= Result() < len(nums)))

    x = numsDivide[0]
    for v in numsDivide[1:]:
        x = gcd(x, v)

    # The point of the first loop is to compute a common divisor of all elements in numsDivide.
    # (It is the greatest, but that property is not needed for the proof.)
    Assert(all(d % x == 0 for d in numsDivide))

    nums.sort()

    for i, v in enumerate(nums):
        # We need to prove the index `i` stays in bounds.
        Invariant(0 <= i <= len(nums))
        # The key invariant is that for all elements checked so far (i.e., the prefix
        # nums[0...i-1]), none of them divide the GCD `x`. This ensures that when we
        # find a divisor, it is the first one in the sorted list.
        Invariant(all(x % nums[j] != 0 for j in range(i)))

        if x % v == 0:
            return i

    # If the loop terminates, it means no element in `nums` was a divisor of `x`.
    Assert(all(x % v != 0 for v in nums))
    return -1