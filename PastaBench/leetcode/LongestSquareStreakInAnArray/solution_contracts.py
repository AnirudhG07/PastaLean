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

def longestSquareStreak(nums: List[int]) -> int:
    # No nontrivial preconditions or postconditions; this function computes
    # the maximum length of a "square streak" (repeated squaring found in nums),
    # or returns -1 if no streak of length > 1 exists.
    ans = -1
    s = set(nums)
    for v in nums:
        # t counts how many times v can be squared while remaining in s
        t = 0
        # loop invariant: t >= 0
        Invariant(t >= 0)
        # At each step, v is the current value in the streak
        while v in s:
            v *= v
            t += 1
        if t > 1:
            ans = max(ans, t)
    return ans