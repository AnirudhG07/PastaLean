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

def minOperations(nums: List[int]) -> int:
    """
    Computes the minimum number of operations to make all elements of `nums` non-zero.
    An operation consists of choosing an index `i` and flipping the last bit
    (i.e., XORing with 1) of all elements from `nums[i]` to the end of the list.
    """
    Ensures(0 <= Result() <= len(nums))
    ans = v = 0
    for x in nums:
        Invariant(ans >= 0)
        Invariant(v == 0 or v == 1)
        Invariant(v == ans % 2)
        x ^= v
        if x == 0:
            ans += 1
            v ^= 1
    return ans