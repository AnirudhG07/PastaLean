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

def finalPrices(prices: List[int]) -> List[int]:
    Requires(all(p >= 0 for p in prices))
    Ensures(len(Result()) == len(prices))
    Ensures(all(p >= 0 for p in Result()))

    stk = []
    for i in reversed(range(len(prices))):
        Invariant(-1 <= i < len(prices))
        Invariant(all(p >= 0 for p in stk))
        # The core property of this algorithm is the monotonic stack.
        # It maintains a non-decreasing sequence of prices seen so far (from right to left).
        Invariant(all(stk[j] <= stk[j+1] for j in range(len(stk) - 1)))

        x = prices[i]
        while stk and x < stk[-1]:
            stk.pop()

        if stk:
            # After the inner loop, the remaining stack top (if any) must be <= x.
            # This is the key fact that guarantees the discounted price remains non-negative.
            Assert(x >= stk[-1])
            prices[i] -= stk[-1]
        stk.append(x)
    return prices