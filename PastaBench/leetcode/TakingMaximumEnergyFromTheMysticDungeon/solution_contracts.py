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
inf = float('inf')

def maximumEnergy(energy: List[int], k: int) -> int:
    Requires(k > 0)
    # The problem implies there's energy to be had. An empty energy list
    # would make the logic return -inf, which can be valid, but typically
    # problem constraints ensure len(energy) >= 1.
    Requires(len(energy) > 0)
    ans = -inf
    n = len(energy)
    for i in range(n - k, n):
        j, s = (i, 0)
        while j >= 0:
            # This invariant is crucial for proving memory safety of `energy[j]`.
            # j >= 0 is the loop condition.
            # j starts at i < n and only decreases (since k > 0), so j < n.
            Invariant(0 <= j < n)
            # This invariant captures that we are moving along an arithmetic
            # progression with common difference k.
            Invariant((i - j) % k == 0)
            # The loop terminates because j strictly decreases and is bounded below by 0.
            Decreases(j)

            s += energy[j]
            ans = max(ans, s)
            j -= k
    return ans