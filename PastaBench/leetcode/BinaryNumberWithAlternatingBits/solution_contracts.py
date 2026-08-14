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

def hasAlternatingBits(n: int) -> bool:
    Requires(n >= 0)
    # A positive integer has alternating bits if and only if `x = n + (n >> 1)` consists of
    # all set bits (i.e., is of the form 2^k - 1). This is equivalent to `x + 1` being
    # a power of two. A number `y > 0` is a power of two if `y & (y - 1) == 0`.
    # Let `y = x + 1`. The condition becomes `(x + 1) & x == 0`.
    # For n >= 0, the positivity condition holds.
    # We assume 'n' in the postcondition refers to its initial value.
    Ensures(Result() == (((n + (n >> 1) + 1) & (n + (n >> 1))) == 0))

    prev = -1
    while n:
        Invariant(n >= 0)
        Invariant(prev == -1 or prev == 0 or prev == 1)
        Decreases(n)

        curr = n & 1
        if prev == curr:
            return False
        prev = curr
        n >>= 1
    return True