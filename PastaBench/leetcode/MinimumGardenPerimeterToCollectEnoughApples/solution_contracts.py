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

def minimumPerimeter(neededApples: int) -> int:
    Requires(neededApples >= 1)
    # The function finds the smallest side length `x` such that the total number of apples,
    # given by `2 * x * (x + 1) * (2 * x + 1)`, is at least `neededApples`.
    # The postconditions assert that the returned perimeter corresponds to a side length `x`
    # that is both sufficient (yields enough apples) and minimal (any smaller side length is insufficient).
    Ensures(2 * (Result() // 8) * (Result() // 8 + 1) * (2 * (Result() // 8) + 1) >= neededApples)
    Ensures((Result() // 8) == 1 or (2 * ((Result() // 8) - 1) * (Result() // 8) * (2 * (Result() // 8) - 1) < neededApples))

    x = 1
    while 2 * x * (x + 1) * (2 * x + 1) < neededApples:
        Invariant(x >= 1)
        # This invariant establishes that for all side lengths smaller than the current x,
        # the number of apples is insufficient. This is the key to proving minimality.
        Invariant(x == 1 or 2 * (x - 1) * x * (2 * x - 1) < neededApples)
        # The term x grows, so (neededApples - x) is a strictly decreasing non-negative integer.
        # Since 4*x^3 < neededApples in the loop, x is always smaller than neededApples for neededApples >= 1.
        Decreases(neededApples - x)
        x += 1
    return x * 8