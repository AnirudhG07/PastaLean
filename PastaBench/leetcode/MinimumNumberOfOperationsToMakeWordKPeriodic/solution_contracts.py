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

def minimumOperationsToMakeKPeriodic(word: str, k: int) -> int:
    Requires(k > 0)
    Requires(len(word) > 0)
    Requires(len(word) % k == 0)
    # The number of operations is non-negative.
    Ensures(Result() >= 0)
    # The number of operations is at most (number of substrings) - 1.
    # Result <= (len(word) / k) - 1  ==>  k * (Result + 1) <= len(word).
    Ensures(k * (Result() + 1) <= len(word))
    n = len(word)
    return n // k - max(Counter((word[i:i + k] for i in range(0, n, k))).values())