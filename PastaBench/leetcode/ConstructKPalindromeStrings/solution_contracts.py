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

def canConstruct(s: str, k: int) -> bool:
    Requires(k >= 1)
    # A string can be partitioned into k non-empty palindromic substrings iff:
    # 1. There are at least as many characters as partitions (len(s) >= k).
    # 2. The number of characters with odd frequencies is at most k, since each
    #    such character must be the center of a distinct palindrome.
    Ensures(Result() == (len(s) >= k and sum((v & 1 for v in Counter(s).values())) <= k))

    if len(s) < k:
        return False

    Assert(len(s) >= k)
    cnt = Counter(s)
    return sum((v & 1 for v in cnt.values())) <= k