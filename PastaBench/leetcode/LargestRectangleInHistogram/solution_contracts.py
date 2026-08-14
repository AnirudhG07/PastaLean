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

def largestRectangleArea(heights: List[int]) -> int:
    Requires(len(heights) > 0)
    Requires(all(h >= 0 for h in heights))

    Ensures(Result() >= 0)
    # The largest rectangle's area is at least the area of any single bar (width 1).
    Ensures(all(Result() >= h for h in heights))

    n = len(heights)
    stk = []
    left = [-1] * n
    right = [n] * n
    for i, h in enumerate(heights):
        Invariant(0 <= i <= n)
        Invariant(len(stk) <= i)
        # All indices in the stack are valid and occurred before the current index i.
        Invariant(all(0 <= j < i for j in stk))
        # The core property: the stack maintains indices of bars with strictly increasing heights.
        Invariant(all(heights[stk[k]] < heights[stk[k+1]] for k in range(len(stk)-1)))

        while stk and heights[stk[-1]] >= h:
            Decreases(len(stk))
            right[stk[-1]] = i
            stk.pop()
        if stk:
            left[i] = stk[-1]
        stk.append(i)

    # Assert the structural properties of the `left` and `right` arrays computed by the loop.
    # These are crucial for proving the postconditions about the final result.
    Assert(all(-1 <= left[k] < k for k in range(n)))
    Assert(all(k < right[k] <= n for k in range(n)))
    # The width of any potential rectangle is at least 1.
    Assert(all(right[k] - left[k] - 1 >= 1 for k in range(n)))

    return max((h * (right[i] - left[i] - 1) for i, h in enumerate(heights)))