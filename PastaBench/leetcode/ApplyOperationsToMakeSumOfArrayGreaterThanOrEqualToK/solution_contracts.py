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


def minOperations(k: int) -> int:
    Requires(k >= 0)
    Ensures(Result() <= k)
    ans = k
    for a in range(k):
        Invariant(0 <= a)
        Invariant(a < k)
        Invariant(ans <= k)
        Decreases(k - 1 - a)
        x = a + 1
        b = (k + x - 1) // x - 1
        ans = min(ans, a + b)
    return ans