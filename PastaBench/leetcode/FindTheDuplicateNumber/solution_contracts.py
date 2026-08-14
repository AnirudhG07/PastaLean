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


def findDuplicate(nums: List[int]) -> int:
    """
    Finds a duplicate number in a list of integers.
    The list `nums` must contain `n+1` integers where `n = len(nums) - 1`,
    and each integer must be in the range `[1, n]`.
    By the pigeonhole principle, at least one number must be duplicated.
    """
    Requires(len(nums) > 1)
    Requires(all(1 <= v < len(nums) for v in nums))

    Ensures(sum(1 for v in nums if v == Result()) > 1)
    Ensures(1 <= Result() < len(nums))

    def f(x: int) -> bool:
        # This key function for the binary search is true iff the count of
        # numbers in `nums` that are less than or equal to `x` is greater than `x`.
        # Under the problem's constraints, `f(x)` is monotonic for `x` in the
        # search range. The first `x` for which this is true must be a
        # duplicate number, as it implies a surplus of numbers in the `[1, x]` range.
        return sum((v <= x for v in nums)) > x

    # The algorithm performs a binary search on the range of possible values [0, n].
    # It finds the smallest value `d` for which there are more than `d` numbers
    # in the input list that are less than or equal to `d`. This `d` must be a duplicate.
    return bisect_left(range(len(nums)), True, key=f)