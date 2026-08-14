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

def countSubstrings(s: str) -> int:
    ans, n = (0, len(s))
    for k in range(n * 2 - 1):
        i, j = (k // 2, (k + 1) // 2)
        while ~i and j < n and (s[i] == s[j]):
            ans += 1
            i, j = (i - 1, j + 1)
    return ans
