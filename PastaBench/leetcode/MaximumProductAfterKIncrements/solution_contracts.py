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

def maximumProduct(nums: List[int], k: int) -> int:
    Requires(len(nums) > 0)
    Requires(k >= 0)
    Requires(all(x >= 0 for x in nums))

    # The core mechanical property of the loop is that it adds a total of k to the sum
    # of the elements in `nums`, one by one. This is the main provable fact.
    initial_sum = sum(nums)
    Ensures(sum(nums) == initial_sum + k)
    Ensures(Result() >= 0)

    heapify(nums)

    # We introduce a loop counter `i` (changing `_` to `i`) to express the invariant.
    # This does not change the runtime behavior as `i` is not used in the loop body.
    for i in range(k):
        Invariant(0 <= i <= k)
        # The sum of elements increases by 1 in each iteration.
        Invariant(sum(nums) == initial_sum + i)
        # All numbers remain non-negative.
        Invariant(all(x >= 0 for x in nums))
        Decreases(k - i)

        heapreplace(nums, nums[0] + 1)

    Assert(sum(nums) == initial_sum + k)

    mod = 10 ** 9 + 7
    return reduce(lambda x, y: x * y % mod, nums)