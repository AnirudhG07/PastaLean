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

def longestSubsequence(arr: List[int], difference: int) -> int:
    Requires(len(arr) > 0)
    Ensures(1 <= Result() <= len(arr))

    f = defaultdict(int)
    for x in arr:
        # INVARIANT: Any value in f represents the length of an arithmetic subsequence
        # found so far. This length must be at least 1 and cannot exceed the total
        # number of elements in the input array.
        Invariant(all(1 <= v <= len(arr) for v in f.values()))

        f[x] = f[x - difference] + 1

    # POST-LOOP: The loop has run at least once since len(arr) > 0, so f is not empty.
    # The invariant guarantees that the maximum value in f, which is the result,
    # is bounded by 1 and the length of the array.
    Assert(all(1 <= v <= len(arr) for v in f.values()))
    Assert(1 <= max(f.values()) <= len(arr))
    return max(f.values())