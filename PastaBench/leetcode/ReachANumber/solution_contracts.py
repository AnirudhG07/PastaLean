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

def reachNumber(target: int) -> int:
    # Let K = Result(). The sum of the first K steps is S_K = K * (K + 1) / 2.
    # The function finds the smallest number of steps K such that S_K is at least
    # abs(target) and has the same parity. The parity condition ensures that
    # abs(target) is reachable from S_K by flipping the signs of some steps,
    # since each flip changes the sum by an even number (2 * step_value).
    Ensures(Result() >= 0)
    # Postcondition 1: The sum of steps is sufficient to reach the target.
    # To avoid division, we write S_K >= abs(target) as K * (K + 1) >= 2 * abs(target).
    Ensures(Result() * (Result() + 1) >= 2 * abs(target))
    # Postcondition 2: The sum of steps and the target have the same parity.
    Ensures((Result() * (Result() + 1) // 2 - abs(target)) % 2 == 0)

    target = abs(target)
    Assert(target >= 0)
    s = k = 0
    while 1:
        Invariant(k >= 0)
        Invariant(s >= 0)
        # This invariant connects the running sum `s` to the step count `k`,
        # stating that s is the k-th triangular number. It is the key to proving
        # that the postconditions hold upon termination.
        Invariant(2 * s == k * (k + 1))
        Invariant(target >= 0)

        if s >= target and (s - target) % 2 == 0:
            return k
        k += 1
        s += k