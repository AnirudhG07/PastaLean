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


def firstMissingPositive(nums: List[int]) -> int:
    n = len(nums)
    Ensures(
        # Every smaller positive < Result() occurs in nums, and Result() does not
        all(any(nums[j] == k for j in range(n)) for k in range(1, Result()))
        and all(nums[j] != Result() for j in range(n))
    )
    # Place each value x in [1..n] into position x-1 if possible
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i <= n)
        # For all processed indices j<i, if nums[j] is in [1..n] then it's at its correct spot
        Invariant(all((not (1 <= nums[j] <= n)) or nums[nums[j] - 1] == nums[j] for j in range(i)))
        while 1 <= nums[i] <= n and nums[i] != nums[nums[i] - 1]:
            j = nums[i] - 1
            nums[i], nums[j] = nums[j], nums[i]
    # Now for every j in [0..n), if nums[j] in [1..n] it must sit at index nums[j]-1
    Assert(all((not (1 <= nums[j] <= n)) or nums[nums[j] - 1] == nums[j] for j in range(n)))
    # Scan for the first position i where nums[i] != i+1
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i <= n)
        # The placement property still holds globally
        Invariant(all((not (1 <= nums[j] <= n)) or nums[nums[j] - 1] == nums[j] for j in range(n)))
        # All values 1..i have been found at their indices 0..i-1
        Invariant(all(nums[k] == k + 1 for k in range(i)))
        if nums[i] != i + 1:
            # Bridge: 1..i+1 all occur in nums exactly at indices 0..i
            Assert(all(any(nums[j] == k for j in range(n)) for k in range(1, i + 1)))
            # And i+1 is indeed missing
            Assert(all(nums[j] != i + 1 for j in range(n)))
            return i + 1
    # If all 1..n are present, the first missing is n+1
    Assert(all(any(nums[j] == k for j in range(n)) for k in range(1, n + 1)))
    Assert(all(nums[j] != n + 1 for j in range(n)))
    return n + 1