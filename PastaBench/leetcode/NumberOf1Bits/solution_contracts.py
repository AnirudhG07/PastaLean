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

def hammingWeight(n: int) -> int:
    Requires(n >= 0)
    # The function's purpose is to count the number of set bits in n's binary
    # representation. In Python 3.10+, this is expressed by `n.bit_count()`.
    # This method requires n >= 0, aligning with our precondition for termination.
    Ensures(Result() == n.bit_count())

    # We introduce an auxiliary variable to refer to the initial value of `n`
    # within the loop invariant, as `n` itself is modified. This is a standard
    # verification pattern for stating invariants that relate loop-carried
    # state to the initial state.
    initial_n = n
    ans = 0
    while n:
        # Loop Invariant: The total number of set bits in the original number equals
        # the number of bits cleared so far (ans) plus the number of bits
        # remaining in the current `n`. This is the core correctness argument.
        Invariant(initial_n.bit_count() == ans + n.bit_count())
        # The value of `n` must remain non-negative for bit_count and for the
        # termination measure to be well-defined.
        Invariant(n >= 0)
        # The value of `n` strictly decreases in each iteration and is bounded
        # below by 0, which guarantees termination.
        Decreases(n)

        n &= n - 1
        ans += 1
    
    # Upon loop termination, n is 0.
    # The main invariant then implies `initial_n.bit_count() == ans + 0`.
    # This bridges the gap between the loop's state and the postcondition.
    Assert(initial_n.bit_count() == ans)
    return ans