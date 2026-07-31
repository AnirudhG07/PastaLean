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

def countSubstrings(s: str) -> int:
    Ensures(Result() >= len(s))
    Ensures(2 * Result() <= len(s) * (len(s) + 1))
    ans, n = (0, len(s))
    for k in range(n * 2 - 1):
        # Invariant: ans counts palindromes centered in 0..k-1, plus at least one for each even k.
        # This implies ans is at least the number of even centers seen so far.
        Invariant(ans >= (k + 1) // 2)
        # Trivial bound on k from the loop structure, useful for later assertions.
        Invariant(0 <= k)

        i, j = (k // 2, (k + 1) // 2)

        # The loop only runs if n >= 1. These assertions bridge from k's bounds to i and j's
        # bounds, which are necessary to prove the safety of the access s[i] and s[j].
        Assert(0 <= i < n)
        Assert(0 <= j < n)

        while ~i and j < n and (s[i] == s[j]):
            # i and j expand outwards from the center k, so their sum is constant.
            Invariant(i + j == k)
            # Bounds on the expanding indices.
            Invariant(-1 <= i and i <= k // 2)
            Invariant((k + 1) // 2 <= j and j <= n)
            # The loop terminates because i moves towards -1.
            Decreases(i)
            ans += 1
            i, j = (i - 1, j + 1)

    # After the loop, the invariant for k = (2*n-1) gives the lower bound.
    Assert(ans >= n)
    # The upper bound holds because every counted item is a unique substring.
    Assert(2 * ans <= n * (n + 1))
    return ans