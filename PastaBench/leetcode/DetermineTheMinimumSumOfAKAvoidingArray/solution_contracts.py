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

def minimumSum(n: int, k: int) -> int:
    Requires(n >= 0)
    Requires(k >= 1)
    # The function computes the sum of the first n integers from the sequence formed by
    # {1, 2, ..., k//2} followed by {k, k+1, k+2, ...}.
    # Let m = k // 2.
    # If n <= m, the sum is 1 + ... + n.
    # If n > m, the sum is (1 + ... + m) + (k + ... + k + (n-m-1)).
    Ensures((n <= k // 2 and 2 * Result() == n * (n + 1)) or
            (n > k // 2 and 2 * Result() == (k // 2) * (k // 2 + 1) + (n - k // 2) * (2 * k + n - k // 2 - 1)))

    s, i = (0, 1)
    vis = set()
    for _ in range(n):
        # We use len(vis) as a proxy for the loop iteration counter, c, which goes from 0 to n-1.
        Invariant(0 <= len(vis) < n)
        Invariant(i >= 1)
        # The main invariant is the closed-form sum for the first `len(vis)` elements.
        Invariant((len(vis) <= k // 2 and 2 * s == len(vis) * (len(vis) + 1)) or
                  (len(vis) > k // 2 and 2 * s == (k // 2) * (k // 2 + 1) + (len(vis) - k // 2) * (2 * k + len(vis) - k // 2 - 1)))
        Decreases(n - len(vis))

        while i in vis:
            i += 1
        vis.add(k - i)
        s += i
        i += 1

    # After the loop, len(vis) == n, so the invariant implies the postcondition for s.
    Assert((n <= k // 2 and 2 * s == n * (n + 1)) or
           (n > k // 2 and 2 * s == (k // 2) * (k // 2 + 1) + (n - k // 2) * (2 * k + n - k // 2 - 1)))
    return s