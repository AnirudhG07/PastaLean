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

def findNumOfValidWords(words: List[str], puzzles: List[str]) -> List[int]:
    Requires(all(len(p) > 0 for p in puzzles))
    Requires(all(all('a' <= c <= 'z' for c in w) for w in words))
    Requires(all(all('a' <= c <= 'z' for c in p) for p in puzzles))
    Ensures(len(Result()) == len(puzzles))
    Ensures(all(v >= 0 for v in Result()))

    cnt = Counter()
    for w in words:
        Invariant(all(0 <= k < (1 << 26) for k in cnt.keys()))
        Invariant(all(v > 0 for v in cnt.values()))
        mask = 0
        for c in w:
            mask |= 1 << ord(c) - ord('a')
        cnt[mask] += 1

    Assert(all(0 <= k < (1 << 26) for k in cnt.keys()))
    Assert(all(v >= 0 for v in cnt.values()))

    ans = []
    for p in puzzles:
        Invariant(len(ans) <= len(puzzles))
        Invariant(all(v >= 0 for v in ans))

        mask = 0
        for c in p:
            mask |= 1 << ord(c) - ord('a')

        x, i, j = (0, ord(p[0]) - ord('a'), mask)
        Assert(0 <= i < 26)
        Assert(0 <= mask < (1 << 26))

        while j:
            Invariant(0 <= j < (1 << 26))
            Invariant(j <= mask)
            Invariant(x >= 0)
            Decreases(j)

            if j >> i & 1:
                x += cnt[j]
            j = j - 1 & mask

        Assert(x >= 0)
        ans.append(x)

    Assert(len(ans) == len(puzzles))
    return ans