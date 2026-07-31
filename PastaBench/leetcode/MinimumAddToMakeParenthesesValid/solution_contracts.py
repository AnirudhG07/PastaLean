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


def minAddToMakeValid(s: str) -> int:
    Requires(all(c in ('(', ')') for c in s))
    Ensures(Result() >= 0)
    Ensures(Result() <= len(s))
    stk = []
    for c in s:
        # The stack always contains only parentheses, which follows from the precondition.
        Invariant(all(p in ('(', ')') for p in stk))
        # A key structural property: the stack always consists of a sequence of ')'
        # followed by a sequence of '('. This is equivalent to being sorted by
        # the key `p == '('`, which puts ')' (False) before '(' (True).
        Invariant(stk == sorted(stk, key=lambda p: p == '('))

        if c == ')' and stk and (stk[-1] == '('):
            stk.pop()
        else:
            stk.append(c)
    return len(stk)