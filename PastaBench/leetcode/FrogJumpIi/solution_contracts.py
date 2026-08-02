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

def maxJump(stones: List[int]) -> int:
    Requires(len(stones) >= 2)
    # This problem assumes stones are sorted positions, making jumps non-negative.
    Requires(all(stones[i] <= stones[i+1] for i in range(len(stones) - 1)))

    # The result is the maximum of a specific set of jumps. This is captured by two facts:
    # 1. The result is an upper bound on all jumps in the set.
    Ensures(Result() >= stones[1] - stones[0])
    Ensures(all(Result() >= stones[k] - stones[k-2] for k in range(2, len(stones))))
    # 2. The result is equal to one of the jumps in the set.
    Ensures(
        Result() == stones[1] - stones[0] or
        any(Result() == stones[k] - stones[k-2] for k in range(2, len(stones)))
    )

    ans = stones[1] - stones[0]
    for i in range(2, len(stones)):
        Invariant(2 <= i <= len(stones))
        # The loop invariant states that `ans` is the running maximum of jumps seen so far.
        # 1. `ans` is an upper bound on jumps processed before this iteration.
        Invariant(ans >= stones[1] - stones[0])
        Invariant(all(ans >= stones[k] - stones[k-2] for k in range(2, i)))
        # 2. `ans` is equal to one of the jumps processed before this iteration.
        Invariant(
            ans == stones[1] - stones[0] or
            any(ans == stones[k] - stones[k-2] for k in range(2, i))
        )

        ans = max(ans, stones[i] - stones[i - 2])

    return ans