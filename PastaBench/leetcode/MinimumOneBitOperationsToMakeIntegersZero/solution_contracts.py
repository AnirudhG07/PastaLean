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

def minimumOneBitOperations(n: int) -> int:
    Requires(n >= 0)
    # This function computes the binary representation `b` from its Gray code
    # representation `n`. The relationship is `n = b ^ (b >> 1)`.
    # We assume `n` in an `Ensures` clause refers to its initial value.
    Ensures(n == Result() ^ (Result() >> 1))

    ans = 0
    # The loop invariant that proves the postcondition is
    # `ans ^ (ans >> 1) == n_initial ^ n_current`. Without syntax to refer to
    # the initial value of `n`, we state weaker, but still useful, invariants.
    while n:
        Invariant(n >= 0)
        Invariant(ans >= 0)
        Decreases(n)
        ans ^= n
        n >>= 1
    return ans