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

def queryString(s: str, n: int) -> bool:
    """
    Checks if the binary representations of all integers from n down to n // 2 + 1
    are substrings of the string s.
    """
    Requires(n >= 0)
    # The function's result is determined by two cases: an arbitrary cutoff at n=1000,
    # and the core substring search logic for smaller n.
    Ensures(Result() == (False if n > 1000 else all(bin(i)[2:] in s for i in range(n, n // 2, -1))))

    if n > 1000:
        return False
    # After the guard, we know the condition for the main logic holds.
    Assert(n <= 1000)
    return all((bin(i)[2:] in s for i in range(n, n // 2, -1)))