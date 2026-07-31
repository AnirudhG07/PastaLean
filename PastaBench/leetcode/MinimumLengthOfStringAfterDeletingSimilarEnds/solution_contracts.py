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

def minimumLength(s: str) -> int:
    Ensures(0 <= Result())
    Ensures(Result() <= len(s))
    i, j = (0, len(s) - 1)
    while i < j and s[i] == s[j]:
        Invariant(0 <= i)
        Invariant(j < len(s))
        Invariant(i <= j + 1)
        Decreases(j - i)
        while i + 1 < j and s[i] == s[i + 1]:
            Invariant(0 <= i)
            Invariant(i < j)
            Invariant(j < len(s))
            Decreases(j - i)
            i += 1
        while i < j - 1 and s[j - 1] == s[j]:
            Invariant(0 <= i)
            Invariant(i < j)
            Invariant(j < len(s))
            Decreases(j - i)
            j -= 1
        i, j = (i + 1, j - 1)
    Assert(i <= j + 1)
    Assert(j - i + 1 <= len(s))
    return max(0, j - i + 1)