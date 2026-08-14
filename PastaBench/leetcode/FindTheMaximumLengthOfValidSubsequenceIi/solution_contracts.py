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

def maximumLength(nums: List[int], k: int) -> int:
    Requires(k > 0)
    Ensures(Result() >= 0)
    Ensures(Result() <= len(nums))

    f = [[0] * k for _ in range(k)]
    ans = 0
    for x in nums:
        x %= k
        Assert(0 <= x < k)
        for j in range(k):
            Invariant(0 <= j)
            Invariant(j <= k)
            Invariant(0 <= x < k)
            Invariant(ans >= 0)

            y = (j - x + k) % k
            Assert(0 <= y < k)
            # The state transition f[x][y] = f[y][x] + 1 corresponds to extending
            # a subsequence with alternating remainders (y, x, y, x, ...).
            # The new element `x` extends a sequence ending in `y`, making a new
            # sequence ending in `x` of length `f[y][x] + 1`.
            f[x][y] = f[y][x] + 1
            ans = max(ans, f[x][y])

    Assert(ans <= len(nums))
    return ans