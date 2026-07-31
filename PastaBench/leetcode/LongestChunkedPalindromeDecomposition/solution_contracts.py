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

def longestDecomposition(text: str) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(text))

    ans = 0
    n = len(text)
    i, j = (0, n - 1)
    while i <= j:
        Invariant(0 <= i)
        Invariant(j < n)
        Invariant(i + j == n - 1)
        Invariant(ans >= 0)
        Invariant(ans % 2 == 0)
        Decreases(j - i)

        k = 1
        ok = False
        while i + k - 1 < j - k + 1:
            Invariant(k >= 1)
            Invariant(not ok)
            Invariant(i + j == n - 1)
            Decreases((j - i + 1) - 2 * k)

            if text[i:i + k] == text[j - k + 1:j + 1]:
                ans += 2
                i += k
                j -= k
                ok = True
                break
            k += 1
        if not ok:
            ans += 1
            break
    return ans