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

def numWays(n: int, k: int) -> int:
    """
    Calculates the number of ways to paint n posts with k colors such that
    no more than two adjacent posts have the same color.
    """
    Requires(n >= 1)
    Requires(k >= 1)
    Ensures(Result() >= 0)
    Ensures(Result() % k == 0)

    # Base case: if there's only one post, the loop is skipped.
    # The function returns f[0] + g[0] = k + 0 = k.
    # This satisfies the postconditions: k >= 1 >= 0, and k % k == 0.
    if n == 1:
        return k
    
    Assert(n > 1)

    f = [0] * n
    g = [0] * n

    # f[i]: number of ways to paint i+1 posts where posts i and i+1 have different colors.
    # g[i]: number of ways to paint i+1 posts where posts i and i+1 have the same color.
    f[0] = k
    g[0] = 0

    for i in range(1, n):
        Invariant(1 <= i < n)
        # Invariants capture that after i-1 iterations, the computed values in f and g
        # are non-negative and are multiples of k. This reflects a structural property
        # of the counting problem: the total number of ways is always a multiple of the
        # number of available colors k.
        Invariant(f[i - 1] >= 0)
        Invariant(g[i - 1] >= 0)
        Invariant(f[i - 1] % k == 0)
        Invariant(g[i - 1] % k == 0)

        f[i] = (f[i - 1] + g[i - 1]) * (k - 1)
        g[i] = f[i - 1]

    # At loop exit, the invariants hold for i=n-1 (the last computed values).
    # These assertions bridge the loop invariants to the final postcondition.
    Assert(f[n - 1] >= 0)
    Assert(g[n - 1] >= 0)
    Assert(f[n - 1] % k == 0)
    Assert(g[n - 1] % k == 0)

    return f[-1] + g[-1]