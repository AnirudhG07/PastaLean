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

def appealSum(s: str) -> int:
    Requires(all('a' <= c <= 'z' for c in s))
    Ensures(Result() > 0 if len(s) > 0 else Result() == 0)

    ans = t = 0
    pos = [-1] * 26
    for i, c in enumerate(s):
        Invariant(0 <= i <= len(s))
        Invariant(t >= 0)
        Invariant(ans >= 0)
        Invariant(i == 0 or ans > 0)
        Invariant(len(pos) == 26)
        Invariant(all(p >= -1 for p in pos))
        Invariant(all(p < i for p in pos))
        Decreases(len(s) - i)
        
        c = ord(c) - ord('a')
        Assert(0 <= c < 26)

        Assert(i - pos[c] >= 1)
        
        t += i - pos[c]
        ans += t
        pos[c] = i
    return ans