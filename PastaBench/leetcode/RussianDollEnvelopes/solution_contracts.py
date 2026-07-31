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

def maxEnvelopes(envelopes: List[List[int]]) -> int:
    Requires(len(envelopes) > 0)
    Ensures(Result() >= 1)
    Ensures(Result() <= len(envelopes))

    # Sort by width (asc), then by height (desc). This is the key insight
    # to reduce the 2D problem to a 1D Longest Increasing Subsequence problem.
    envelopes.sort(key=lambda x: (x[0], -x[1]))

    # `d` stores the smallest tail of all increasing subsequences of a given length.
    # The length of `d` is the length of the LIS found so far.
    d = [envelopes[0][1]]

    for _, h in envelopes[1:]:
        # Invariant: d is never empty, so the access `d[-1]` is always safe.
        Invariant(len(d) >= 1)
        # Invariant: The length of the LIS can't exceed the total number of envelopes.
        Invariant(len(d) <= len(envelopes))

        if h > d[-1]:
            d.append(h)
        else:
            # Find the position to replace an element in `d` with `h` to maintain
            # an increasing sequence with a smaller tail.
            # This relies on the implicit invariant that `d` is sorted.
            idx = bisect_left(d, h)
            d[idx] = h

    # The length of `d` is the answer. The loop invariants establish the bounds.
    Assert(1 <= len(d))
    Assert(len(d) <= len(envelopes))
    return len(d)