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

def countLetters(s: str) -> int:
    n = len(s)
    Ensures(Result() >= 0)
    Ensures(2 * Result() <= n * (n + 1))

    i = ans = 0
    while i < n:
        Invariant(0 <= i <= n)
        Invariant(ans >= 0)
        Invariant(2 * ans <= i * (i + 1))
        Decreases(n - i)

        j = i
        while j < n and s[j] == s[i]:
            Invariant(i <= j <= n)
            Decreases(n - j)

            j += 1
        ans += (1 + j - i) * (j - i) // 2
        i = j
    return ans