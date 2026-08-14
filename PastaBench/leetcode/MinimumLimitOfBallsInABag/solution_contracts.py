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

def minimumSize(nums: List[int], maxOperations: int) -> int:
    Requires(len(nums) > 0)
    Requires(all(x > 0 for x in nums))
    Requires(maxOperations >= 0)

    # The result `R` must be the smallest positive integer such that the total
    # operations to reduce all numbers in `nums` to be at most `R` does not
    # exceed `maxOperations`. The number of operations for a number `x` is `(x - 1) // R`.

    # Ensures the result is a feasible penalty (number of operations is within the budget).
    Ensures(sum(((x - 1) // Result() for x in nums)) <= maxOperations)
    # Ensures the result is the MINIMAL feasible penalty.
    Ensures(Result() == 1 or sum(((x - 1) // (Result() - 1) for x in nums)) > maxOperations)
    # The result is positive and bounded by the maximum initial value.
    Ensures(1 <= Result())
    Ensures(Result() <= max(nums))

    def check(mx: int) -> bool:
        # This predicate is true iff `mx` is a feasible maximum value.
        Requires(mx > 0)
        Ensures(Result() == (sum(((x - 1) // mx for x in nums)) <= maxOperations))
        return sum(((x - 1) // mx for x in nums)) <= maxOperations
    return bisect_left(range(1, max(nums) + 1), True, key=check) + 1