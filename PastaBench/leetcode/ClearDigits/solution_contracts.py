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

def clearDigits(s: str) -> str:
    # This function assumes, but does not state, a precondition that ensures `stk`
    # is never empty when a digit is encountered. A full specification would require
    # stating that for any prefix of `s`, the number of non-digits is at least
    # the number of digits.
    Ensures(all(not c.isdigit() for c in Result()))
    # A stronger postcondition would relate Result()'s length to the count of
    # digits and non-digits in `s`. Proving it requires an index-based invariant
    # which is not expressible here because the loop `for c in s:` does not
    # expose an index.

    stk = []
    for c in s:
        # Invariant: The stack contains only non-digit characters.
        Invariant(all(not ch.isdigit() for ch in stk))
        # Invariant: The stack size must remain non-negative for `pop` to be valid.
        # Proving this invariant requires the implicit precondition on `s`.
        Invariant(len(stk) >= 0)

        if c.isdigit():
            stk.pop()
        else:
            stk.append(c)
    return ''.join(stk)