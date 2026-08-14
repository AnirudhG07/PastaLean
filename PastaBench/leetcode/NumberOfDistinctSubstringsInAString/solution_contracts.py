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

def countDistinct(s: str) -> int:
    # The number of distinct substrings is at least the length of the string,
    # because the n substrings s[0:1], s[0:2], ..., s[0:n] all have different lengths
    # and are therefore all distinct. This holds even for n=0 (0 >= 0).
    Ensures(Result() >= len(s))
    # The number of distinct substrings cannot exceed the total number of
    # non-empty substrings, which is n * (n + 1) / 2.
    Ensures(2 * Result() <= len(s) * (len(s) + 1))
    n = len(s)
    return len({s[i:j] for i in range(n) for j in range(i + 1, n + 1)})