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

def closestToTarget(arr: List[int], target: int) -> int:
    Requires(len(arr) > 0)

    Ensures(Result() >= 0)
    # The function finds the minimum difference using bitwise ANDs of contiguous subarrays.
    # Since any individual element `x` from `arr` is a valid subarray of length one,
    # the final result must be at least as small as `abs(x - target)` for any `x`.
    Ensures(forall(lambda x: Result() <= abs(x - target), arr))

    ans = abs(arr[0] - target)
    s = {arr[0]}
    for x in arr:
        # The running minimum difference `ans` is always non-negative.
        Invariant(ans >= 0)
        # The set of candidate values `s` is kept non-empty throughout the loop,
        # which ensures the inner `min()` call is always valid.
        Invariant(s)

        s = {x & y for y in s} | {x}
        ans = min(ans, min((abs(y - target) for y in s)))
    return ans