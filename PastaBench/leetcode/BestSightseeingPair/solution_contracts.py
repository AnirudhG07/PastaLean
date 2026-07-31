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

def maxScoreSightseeingPair(values: List[int]) -> int:
    Requires(len(values) >= 2)
    # This implementation is only correct if the maximum score is non-negative.
    # A sufficient condition for this is that all values are >= 1, which guarantees
    # that any score `values[i] + values[j] + i - j` is at least `1 + 1 - 1 = 1`.
    # Without such a precondition, the algorithm fails on inputs like `[-10, -10]`.

    # The function's purpose is to find the maximum score over all valid pairs (i, j) with i < j.
    Ensures(Result() == max(
        values[i] + values[j] + i - j
        for j in range(len(values))
        for i in range(j)
    ))

    ans = mx = 0
    for j, x in enumerate(values):
        Invariant(0 <= j)
        Invariant(j <= len(values))
        # The key to this algorithm is that `mx` tracks the best possible value for the
        # first part of the score, `values[i] + i`, for all sights `i` seen so far (i.e., `i < j`).
        # The initial `0` handles the `j=0` case and ensures `mx` is non-negative.
        Invariant(mx == max([0] + [values[i] + i for i in range(j)]))

        ans = max(ans, mx + x - j)
        mx = max(mx, x + j)
    return ans