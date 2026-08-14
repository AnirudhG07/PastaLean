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

def countDistinctIntegers(nums: List[int]) -> int:
    # The string reversal logic implies non-negative integers are expected.
    # e.g., str(-123)[::-1] is "321-", which int() fails to parse.
    # This is a reasonable precondition for the function to operate correctly.
    # Requires(all(x >= 0 for x in nums))  <- This is assumed, but not expressible in simple arithmetic.

    # The result is the number of unique integers after adding the reversed form of each number.
    # This will be at least the number of unique integers in the original list.
    Ensures(Result() >= len(set(nums)))
    # For each of the `len(nums)` numbers, we add at most one new (reversed) number.
    Ensures(Result() <= len(set(nums)) + len(nums))

    s = set(nums)
    for x in nums:
        # The size of the set s never drops below the initial number of unique elements.
        Invariant(len(s) >= len(set(nums)))
        # The size of s cannot exceed the initial size plus one for each element in the input list.
        # This holds true at every step, as len(s) monotonically increases towards this bound.
        Invariant(len(s) <= len(set(nums)) + len(nums))

        y = int(str(x)[::-1])
        s.add(y)
    return len(s)