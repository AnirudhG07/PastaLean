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

def minimumTime(time: List[int], totalTrips: int) -> int:
    Requires(len(time) > 0)
    Requires(all(t > 0 for t in time))
    Requires(totalTrips > 0)

    # THE POINT: The result is the minimum time to achieve `totalTrips`.
    # This implies two conditions:
    # 1. At the returned time, the goal is met.
    Ensures(sum(Result() // v for v in time) >= totalTrips)
    # 2. At the time just before, the goal was not met (proof of minimality).
    Ensures(sum((Result() - 1) // v for v in time) < totalTrips)

    # An upper bound for the binary search is the time it would take for the fastest bus
    # to complete all trips by itself.
    mx = min(time) * totalTrips

    # This upper bound is guaranteed to be a time at which `totalTrips` is met or exceeded,
    # which justifies the correctness of the binary search on the range [0, mx].
    Assert(sum(mx // v for v in time) >= totalTrips)

    # The function uses binary search (`bisect_left`) to find the smallest integer `t`
    # for which the number of trips is >= totalTrips.
    return bisect_left(range(mx), totalTrips, key=lambda x: sum((x // v for v in time)))