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

def dailyTemperatures(temperatures: List[int]) -> List[int]:
    n = len(temperatures)
    Requires(n >= 0)
    Ensures(len(Result()) == n)
    stk = []
    ans = [0] * n
    # We maintain i in range and ans length fixed
    for i in range(n - 1, -1, -1):
        Invariant(0 <= i)
        Invariant(i < n)
        Invariant(len(ans) == n)
        Invariant(all(0 <= idx < n for idx in stk))
        while stk and temperatures[stk[-1]] <= temperatures[i]:
            stk.pop()
        if stk:
            # The next warmer day index is above i
            Assert(stk[-1] > i)
            ans[i] = stk[-1] - i
        stk.append(i)
    return ans