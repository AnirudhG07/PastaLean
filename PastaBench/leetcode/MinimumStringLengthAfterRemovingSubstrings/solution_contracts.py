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

def minLength(s: str) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(s))
    stk = ['']
    for c in s:
        # This invariant is crucial for proving that the access `stk[-1]` is always safe.
        # Initially, len(stk) is 1. If len(stk) is 1, stk[-1] is '', so the `if`
        # condition is false and we always append, making the length 2.
        # If len(stk) > 1, pop is safe and leaves len(stk) >= 1.
        Invariant(len(stk) >= 1)
        if c == 'B' and stk[-1] == 'A' or (c == 'D' and stk[-1] == 'C'):
            stk.pop()
        else:
            stk.append(c)
    return len(stk) - 1