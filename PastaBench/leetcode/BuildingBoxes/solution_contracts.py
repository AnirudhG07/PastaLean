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


def minimumBoxes(n: int) -> int:
    Requires(n >= 0)
    s, k = (0, 1)
    while s + k * (k + 1) // 2 <= n:
        Invariant(n - s >= 0)
        Invariant(k >= 1)
        Decreases(n - s)
        s += k * (k + 1) // 2
        k += 1
    k -= 1
    ans = k * (k + 1) // 2
    k = 1
    while s < n:
        Invariant(k >= 1)
        Invariant(2 * (n - s) + k > 0)
        Decreases(2 * (n - s) + k)
        ans += 1
        s += k
        k += 1
    return ans