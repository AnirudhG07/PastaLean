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

def mostCompetitive(nums: List[int], k: int) -> List[int]:
    Requires(0 <= k)
    Requires(k <= len(nums))
    Ensures(len(Result()) == k)

    stk = []
    n = len(nums)
    for i, v in enumerate(nums):
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(len(stk) <= k)
        # Key invariant: there are always enough elements available (in the stack
        # plus the remainder of the input) to be able to form a final result of size k.
        Invariant(len(stk) + (n - i) >= k)

        while stk and stk[-1] > v and (len(stk) + n - i > k):
            stk.pop()

        if len(stk) < k:
            stk.append(v)

    # After the loop, i is conceptually n.
    # The invariants `len(stk) <= k` and `len(stk) + (n - i) >= k`
    # imply `len(stk) <= k` and `len(stk) + (n - n) >= k` => `len(stk) >= k`.
    # Thus, len(stk) must be exactly k.
    Assert(len(stk) == k)
    return stk