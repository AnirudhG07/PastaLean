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


def findPermutation(s: str) -> List[int]:
    n = len(s)
    Requires(all(c in ('D', 'I') for c in s))
    # The result is a permutation of 1..n+1 matching the 'D'/'I' pattern
    Ensures(sorted(Result()) == list(range(1, n + 2)))
    Ensures(all(
        (s[k] == 'D' and Result()[k] > Result()[k+1]) or
        (s[k] == 'I' and Result()[k] < Result()[k+1])
        for k in range(n)
    ))
    ans = list(range(1, n + 2))
    Assert(len(ans) == n + 1)
    i = 0
    while i < n:
        Invariant(0 <= i)
        Invariant(i <= n)
        # Prefix [0..i) already satisfies the pattern
        Invariant(all(
            (s[k] == 'D' and ans[k] > ans[k+1]) or
            (s[k] == 'I' and ans[k] < ans[k+1])
            for k in range(i)
        ))
        Decreases(n - i)
        j = i
        while j < n and s[j] == 'D':
            Invariant(0 <= j)
            Invariant(j <= n)
            Invariant(i <= j)
            Decreases(n - j)
            j += 1
        # Reverse the block [i..j] to satisfy all 'D's in that segment
        ans[i:j+1] = ans[i:j+1][::-1]
        i = max(i + 1, j)
    # Bridge to the full postcondition
    Assert(all(
        (s[k] == 'D' and ans[k] > ans[k+1]) or
        (s[k] == 'I' and ans[k] < ans[k+1])
        for k in range(n)
    ))
    return ans