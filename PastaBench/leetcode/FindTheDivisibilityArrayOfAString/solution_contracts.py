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


def divisibilityArray(word: str, m: int) -> List[int]:
    Requires(m > 0)
    # The result has one entry per character in the input
    Ensures(len(Result()) == len(word))
    # Each entry is 0 or 1 and indicates whether the corresponding prefix is divisible by m
    Ensures(all(Result()[i] in (0, 1) for i in range(len(word))))
    Ensures(all((Result()[i] == 1) == (int(word[:i+1]) % m == 0)
                for i in range(len(word))))

    ans = []
    x = 0
    for c in word:
        # x is always a valid remainder mod m
        Invariant(0 <= x)
        Invariant(x < m)

        # update remainder for the next prefix
        x = (x * 10 + int(c)) % m
        # record divisibility of this prefix
        ans.append(1 if x == 0 else 0)
    return ans