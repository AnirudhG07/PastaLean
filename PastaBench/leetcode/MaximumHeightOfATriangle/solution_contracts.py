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

def maxHeightOfTriangle(red: int, blue: int) -> int:
    Requires(red >= 0)
    Requires(blue >= 0)
    # The result `h` corresponds to a valid triangle, so the number of balls
    # required, h*(h+1)/2, must not exceed the total available.
    Ensures(Result() * (Result() + 1) <= 2 * (red + blue))
    Ensures(Result() >= 0)

    ans = 0
    # The loop runs twice, once for each starting color possibility.
    # The variable `ans` tracks the maximum height found so far.
    for k in range(2):
        Invariant(ans >= 0)

        c = [red, blue]
        i, j = (1, k)
        # This loop simulates building the triangle row by row.
        while i <= c[j]:
            # Termination: The total number of balls `c[0] + c[1]` is a
            # non-negative integer that strictly decreases each iteration.
            Decreases(c[0] + c[1])

            # Loop Invariants:
            # 1. Row counter `i` is positive.
            Invariant(i >= 1)
            # 2. Color index `j` is always 0 or 1.
            Invariant(j == 0 or j == 1)
            # 3. Ball counts are always non-negative.
            Invariant(c[0] >= 0)
            Invariant(c[1] >= 0)
            # 4. (The point) The total number of balls is conserved:
            #    balls_remaining + balls_used == total_balls.
            #    balls_used for height i-1 is (i-1)*i/2.
            Invariant(2 * (c[0] + c[1]) + (i - 1) * i == 2 * (red + blue))
            # 5. The running answer `ans` is non-negative.
            Invariant(ans >= 0)

            c[j] -= i
            # Bridge assertion: the loop guard `i <= c[j]` ensures
            # the ball count remains non-negative after subtraction.
            Assert(c[j] >= 0)
            j ^= 1
            ans = max(ans, i)
            i += 1
    return ans