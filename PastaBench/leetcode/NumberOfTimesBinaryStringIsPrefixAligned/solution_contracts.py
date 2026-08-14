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

def numTimesAllBlue(flips: List[int]) -> int:
    Requires(set(flips) == set(range(1, len(flips) + 1)))
    Ensures(0 <= Result() <= len(flips))

    ans = mx = 0
    for i, x in enumerate(flips, 1):
        # i is the number of bulbs flipped, from 1 to len(flips).
        Invariant(1 <= i <= len(flips))
        # mx is the maximum bulb index seen so far. It cannot exceed the total number of bulbs.
        Invariant(0 <= mx <= len(flips))
        # ans is the count of "all blue" moments, which cannot exceed the number of steps taken.
        Invariant(0 <= ans < i)

        mx = max(mx, x)
        ans += mx == i

    Assert(0 <= ans <= len(flips))
    return ans