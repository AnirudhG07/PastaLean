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

def maxA(n: int) -> int:
    Requires(n >= 0)
    # The result is the maximum number of A's, which is always at least n
    # (achieved by just typing the 'A' key n times).
    Ensures(Result() >= n)

    dp = list(range(n + 1))
    Assert(len(dp) == n + 1)

    for i in range(3, n + 1):
        # Loop counter stays within the bounds of the dp array.
        Invariant(3 <= i <= n + 1)
        Invariant(len(dp) == n + 1)
        # Key invariant: Every entry in the dp table is at least its index.
        # This is true after initialization. The inner loop only increases dp[i]
        # from its initial value of i, using non-negative terms, so the
        # property is maintained for all elements.
        Invariant(all(dp[k] >= k for k in range(n + 1)))

        for j in range(2, i - 1):
            # Index bounds are critical for proving memory safety of the array accesses.
            Invariant(0 <= i < len(dp))
            Invariant(0 <= j - 1 < len(dp))

            dp[i] = max(dp[i], dp[j - 1] * (i - j))

    # The loop invariant `all(dp[k] >= k ...)` holds upon termination.
    # A specific instance of this is that dp[n] >= n, which is what the
    # postcondition requires, since Result() will be dp[-1] == dp[n].
    Assert(dp[n] >= n)
    return dp[-1]