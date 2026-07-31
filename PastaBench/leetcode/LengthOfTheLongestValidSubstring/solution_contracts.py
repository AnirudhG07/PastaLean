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

def longestValidSubstring(word: str, forbidden: List[str]) -> int:
    Ensures(0 <= Result() <= len(word))

    s = set(forbidden)
    ans = i = 0
    for j in range(len(word)):
        Invariant(0 <= j <= len(word))
        Invariant(0 <= i <= j)
        Invariant(0 <= ans <= j)
        Invariant(ans <= len(word))

        for k in range(j, max(j - 10, i - 1), -1):
            # Loop bounds imply max(j - 10, i - 1) < k <= j.
            # With outer invariants 0 <= i and j < len(word),
            # this implies 0 <= k < len(word), making the slice safe.
            Invariant(0 <= j < len(word))
            Invariant(0 <= i <= j)
            Invariant(0 <= k < len(word))
            Invariant(k <= j)
            if word[k:j + 1] in s:
                i = k + 1
                break
        ans = max(ans, j - i + 1)
        Assert(0 <= ans <= j + 1)
    return ans