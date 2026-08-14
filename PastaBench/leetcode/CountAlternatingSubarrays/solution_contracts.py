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


def countAlternatingSubarrays(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    # The total number of alternating subarrays is at least the number of
    # single-element subarrays, which is equal to len(nums).
    Ensures(Result() >= len(nums))
    
    # Initialize count and current streak length for the first element.
    # An array with one element has one alternating subarray: itself.
    ans = s = 1
    
    for a, b in pairwise(nums):
        # s is the length of the current alternating subarray streak.
        # It's always at least 1 (for the single-element subarray).
        Invariant(s >= 1)
        # ans is the running total, which accumulates positive streak lengths (s).
        # Thus, ans is always positive and at least as large as the last streak added.
        Invariant(ans >= s)

        s = s + 1 if a != b else 1
        ans += s
    return ans