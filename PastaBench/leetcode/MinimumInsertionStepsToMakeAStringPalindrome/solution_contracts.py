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

def minInsertions(s: str) -> int:
    Requires(len(s) >= 0)
    # The result is a nonnegative number of insertions, at most the length of s.
    Ensures(0 <= Result())
    Ensures(Result() <= len(s))

    @cache
    def dfs(i: int, j: int) -> int:
        # dfs is called only when 0 <= i, j < len(s) and i <= j+1
        Requires(0 <= i)
        Requires(j < len(s))
        Requires(i <= j + 1)
        # For substring s[i..j], the needed insertions is between 0 and its length.
        Ensures(0 <= Result())
        Ensures(Result() <= j - i + 1)
        # Termination measure: the gap j - i strictly decreases on recursion when i < j.
        Decreases(j - i)

        if i >= j:
            return 0
        if s[i] == s[j]:
            return dfs(i + 1, j - 1)
        return 1 + min(dfs(i + 1, j), dfs(i, j - 1))

    return dfs(0, len(s) - 1)