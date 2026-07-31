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

def maximumGroups(grades: List[int]) -> int:
    """
    Calculates the maximum number of groups that can be formed from a list of grades.
    The problem is to find the maximum integer k such that the sum 1 + 2 + ... + k <= n,
    where n is the number of grades. This is equivalent to finding the maximum k
    such that k * (k + 1) / 2 <= n, or k * (k + 1) <= 2 * n.
    """
    Requires(len(grades) >= 0)
    Ensures(Result() >= 0)
    # The result `k` is the largest integer satisfying k*(k+1) <= 2*n.
    # This means k satisfies the inequality, but k+1 does not.
    Ensures(Result() * (Result() + 1) <= 2 * len(grades))
    Ensures((Result() + 1) * (Result() + 2) > 2 * len(grades))

    n = len(grades)
    # This is equivalent to finding the largest `x` in `range(n + 1)`
    # such that `x * (x + 1) <= 2 * n`.
    # `bisect_right` with key `f(x)=x*x+x` finds the insertion point `i`
    # for `2*n`, so all elements before `i` have `f(x) <= 2*n`.
    # The largest such element's index is `i-1`.
    return bisect_right(range(n + 1), n * 2, key=lambda x: x * x + x) - 1