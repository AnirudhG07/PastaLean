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

def lengthOfLIS(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    # The result is the length of a subsequence. It must be at least 1 (any
    # single element) and at most the total number of elements.
    Ensures(1 <= Result() <= len(nums))

    n = len(nums)
    f = [1] * n
    for i in range(1, n):
        # The loop counter `i` is bounded by the length of the list.
        Invariant(1 <= i <= n)
        # The DP table `f` maintains its size.
        Invariant(len(f) == n)
        for j in range(i):
            # The inner loop counter `j` is bounded by the outer counter `i`.
            Invariant(0 <= j <= i)
            # Within the inner loop's body, `i` is strictly less than `n`.
            Invariant(1 <= i < n)

            if nums[j] < nums[i]:
                f[i] = max(f[i], f[j] + 1)
    
    # The lower bound Result() >= 1 is provable because f is initialized with 1s
    # and its values only ever increase. The upper bound requires an inductive
    # proof over the array f (i.e., that f[k] <= k+1 for all k), which is
    # difficult to express without quantified invariants, but is a true property.
    return max(f)