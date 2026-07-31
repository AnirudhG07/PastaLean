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

def lengthOfLongestSubstringTwoDistinct(s: str) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(s))

    cnt = Counter()
    ans = j = 0
    for i, c in enumerate(s):
        Invariant(0 <= i <= len(s))
        Invariant(0 <= j <= i)
        Invariant(ans >= 0)
        Invariant(ans <= i)
        Invariant(len(cnt) <= 2)

        cnt[c] += 1
        while len(cnt) > 2:
            Invariant(len(cnt) > 2)
            Invariant(0 <= j < i)
            Invariant(i < len(s))
            Decreases(i - j)

            cnt[s[j]] -= 1
            if cnt[s[j]] == 0:
                cnt.pop(s[j])
            j += 1
        
        Assert(len(cnt) <= 2)
        Assert(0 <= j <= i)
        
        ans = max(ans, i - j + 1)
    return ans