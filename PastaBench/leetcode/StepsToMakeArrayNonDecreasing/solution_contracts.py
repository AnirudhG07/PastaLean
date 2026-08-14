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

def totalSteps(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(Result() >= 0)
    Ensures(Result() < len(nums))

    stk = []
    ans, n = (0, len(nums))
    dp = [0] * n
    Assert(len(dp) == n)
    for i in range(n - 1, -1, -1):
        Invariant(0 <= i < n)
        while stk and nums[i] > nums[stk[-1]]:
            Decreases(len(stk))
            # This assertion is key to proving memory safety. It holds because `stk`
            # only ever contains valid indices `j` that were previously added, where
            # `0 <= j < n` was true.
            Assert(0 <= stk[-1] < n)
            dp[i] = max(dp[i] + 1, dp[stk.pop()])
        stk.append(i)
    return max(dp)