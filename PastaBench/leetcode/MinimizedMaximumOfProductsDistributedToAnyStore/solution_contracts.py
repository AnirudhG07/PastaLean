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

def minimizedMaximum(n: int, quantities: List[int]) -> int:
    Requires(n > 0)
    Requires(len(quantities) > 0)
    Requires(all(q > 0 for q in quantities))
    # A solution is guaranteed to exist if the number of stores is at least the
    # number of distinct item types, as each type can be distributed to a
    # separate set of stores. This precondition ensures the function's postconditions hold.
    Requires(n >= len(quantities))

    # The result must be a positive integer.
    Ensures(Result() >= 1)
    # The result `x` must be a valid solution: the total number of stores required
    # for a capacity of `x` must not exceed the available stores `n`.
    Ensures(sum(((q + Result() - 1) // Result() for q in quantities)) <= n)
    # The result must be the *minimal* such integer, meaning that a capacity of
    # `Result() - 1` is insufficient (unless the result is 1).
    Ensures(Result() == 1 or sum(((q + (Result() - 1) - 1) // (Result() - 1) for q in quantities)) > n)

    def check(x):
        return sum(((v + x - 1) // x for v in quantities)) <= n
    return 1 + bisect_left(range(1, 10 ** 6), True, key=check)