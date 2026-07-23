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

def removeAlmostEqualCharacters(word: str) -> int:
    Ensures(Result() >= 0)
    Ensures(2 * Result() <= len(word))
    ans = 0
    i, n = (1, len(word))
    while i < n:
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(2 * ans <= i)
        Decreases(n - i)
        if abs(ord(word[i]) - ord(word[i - 1])) < 2:
            ans += 1
            i += 2
        else:
            i += 1
    Assert(ans >= 0)
    Assert(2 * ans <= n)
    return ans