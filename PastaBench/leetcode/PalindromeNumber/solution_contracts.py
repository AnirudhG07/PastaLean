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

def isPalindrome(x: int) -> bool:
    # The function's purpose is to determine if the decimal representation of x is a palindrome.
    # We assume the `x` in the Ensures clause refers to its initial value.
    Ensures(Result() == (str(x) == str(x)[::-1]))

    if x < 0 or (x and x % 10 == 0):
        return False
    
    # Bridge assertion: on this path, x is non-negative and not a non-zero number ending in 0.
    # This is the precondition for the logic that follows.
    Assert(x >= 0)
    Assert(x == 0 or x % 10 != 0)

    y = 0
    # This loop computes the reversed second half of the number `x` into `y`.
    # It stops when half the digits have been processed.
    while y < x:
        # Loop invariants establishing basic properties needed for reasoning.
        Invariant(y >= 0)
        Invariant(x >= 0)

        # The termination measure: x is a non-negative integer that strictly
        # decreases in each iteration, guaranteeing the loop terminates.
        Decreases(x)
        
        y = y * 10 + x % 10
        x //= 10
        
    # At this point, `x` holds the first half of the digits and `y` holds the
    # reversed second half.
    # For an even number of digits, `x` and `y` should be equal (e.g., 1221 -> x=12, y=12).
    # For an odd number of digits, `y` includes the middle digit, so we compare
    # `x` with `y // 10` (e.g., 12321 -> x=12, y=123).
    return x in (y, y // 10)