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

def maxTotalReward(rewardValues: List[int]) -> int:
    Requires(len(rewardValues) >= 1)
    Requires(all(v >= 1 for v in rewardValues))

    Ensures(Result() >= 0)
    Ensures(Result() < 2 * max(rewardValues))

    nums = sorted(set(rewardValues))
    f = 1
    for v in nums:
        Invariant(v >= 1)
        Invariant(f >= 1)
        # The maximum sum achievable so far is bounded by twice the current reward value.
        # This holds because new sums are formed by `s + v` where `s < v`, so `s + v < 2v`.
        # The old max sum was bounded by `2 * v_previous < 2 * v`.
        Invariant(f.bit_length() - 1 < 2 * v)

        f |= (f & (1 << v) - 1) << v

    # After the loop, the invariant holds for the last value of v, which is max(rewardValues).
    # This assertion bridges the loop invariant to the postcondition.
    Assert(f.bit_length() - 1 < 2 * max(rewardValues))
    return f.bit_length() - 1