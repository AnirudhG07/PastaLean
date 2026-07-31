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

def distanceBetweenBusStops(distance: List[int], start: int, destination: int) -> int:
    Requires(len(distance) > 0)
    Requires(0 <= start < len(distance))
    Requires(0 <= destination < len(distance))
    Requires(all(d >= 0 for d in distance))
    Ensures(Result() >= 0)
    Ensures(2 * Result() <= sum(distance))

    s = sum(distance)
    t, n = (0, len(distance))

    # The loop calculates the distance `t` in the clockwise direction from `start` to `destination`.
    # The termination measure is the number of clockwise steps remaining to reach the destination.
    while start != destination:
        Decreases((destination - start + n) % n)
        Invariant(0 <= start < n)
        Invariant(t >= 0)
        Invariant(t <= s)

        t += distance[start]
        start = (start + 1) % n
        
    # The result is the minimum of the clockwise distance `t` and the counter-clockwise distance `s - t`.
    return min(t, s - t)