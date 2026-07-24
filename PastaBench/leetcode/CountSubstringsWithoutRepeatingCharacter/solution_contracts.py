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

def numberOfSpecialSubstrings(s: str) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(s) * (len(s) + 1) // 2)
    cnt = Counter()
    ans = j = 0
    for i, c in enumerate(s):
        Invariant(ans >= 0)
        Invariant(ans <= (i + 1) * (i + 2) // 2)
        Invariant(0 <= j)
        Invariant(j <= i + 1)
        cnt[c] += 1
        while cnt[c] > 1:
            cnt[s[j]] -= 1
            j += 1
        Assert(cnt[c] == 1)
        ans += i - j + 1
    Assert(ans <= len(s) * (len(s) + 1) // 2)
    return ans