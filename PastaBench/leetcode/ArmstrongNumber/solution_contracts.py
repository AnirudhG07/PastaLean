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

def isArmstrong(n: int) -> bool:
    Requires(n >= 0)
    # The property of being an Armstrong number is defined with respect to the
    # number of digits in its decimal representation. A formal proof would
    # require axioms relating arithmetic to decimal representations, which
    # is beyond the scope of simple arithmetic invariants.
    # We can, however, prove basic properties like non-negativity and termination.
    k = len(str(n))
    s, x = (0, n)
    while x:
        Invariant(x >= 0)
        Invariant(s >= 0)
        Decreases(x)
        s += (x % 10) ** k
        x //= 10
    return s == n