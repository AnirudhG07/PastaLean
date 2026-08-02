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


def triangularSum(nums: List[int]) -> int:
    Requires(len(nums) >= 1)
    Requires(all(0 <= x < 10 for x in nums))
    Ensures(0 <= Result() < 10)

    for k in range(len(nums) - 1, 0, -1):
        Invariant(1 <= k < len(nums))
        # The core property is that the active prefix of the array always
        # consists of single-digit numbers. This is true initially due to the
        # precondition and is preserved by the modulo 10 update rule.
        Invariant(all(0 <= nums[j] < 10 for j in range(k + 1)))
        Decreases(k)

        for i in range(k):
            Invariant(0 <= i <= k)
            Decreases(k - i)

            # The update needs `nums[i+1]`. `i` goes up to `k-1`, so we need `k < len(nums)`.
            # This is guaranteed by the outer loop's invariant.
            Assert(i + 1 < len(nums))
            nums[i] = (nums[i] + nums[i + 1]) % 10

    # If len(nums) > 1, the loop terminates after k=1, where nums[0] is updated
    # one last time. The result is guaranteed to be in [0, 9].
    # If len(nums) == 1, the loop is skipped and nums[0] is in [0, 9] by precondition.
    Assert(0 <= nums[0] < 10)
    return nums[0]