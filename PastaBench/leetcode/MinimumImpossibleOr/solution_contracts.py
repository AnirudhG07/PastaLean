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


def minImpossibleOR(nums: List[int]) -> int:
    """
    Finds the smallest power of 2 that is not present in the input list `nums`.
    This value is also the smallest positive integer that cannot be formed by a
    bitwise OR of any subset of `nums`.
    """
    # The function is guaranteed to find a result, as it doesn't handle the case
    # where all powers of 2 up to 2**31 are present.
    Requires(any((1 << i) not in set(nums) for i in range(32)))

    # The result must be a power of 2.
    Ensures(Result() > 0 and (Result() & (Result() - 1)) == 0)
    # The result, by definition of the search, is not in the input set.
    Ensures(Result() not in set(nums))
    # The result must be the *smallest* such power of 2. This means that all
    # powers of 2 smaller than the result *are* present in the set.
    Ensures(all((1 << i) in set(nums) for i in range(32) if (1 << i) < Result()))

    s = set(nums)
    return next((1 << i for i in range(32) if 1 << i not in s))