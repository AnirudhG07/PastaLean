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

def makeAntiPalindrome(s: str) -> str:
    cs = sorted(s)
    n = len(cs)
    m = n // 2
    if cs[m] == cs[m - 1]:
        i = m
        while i < n and cs[i] == cs[i - 1]:
            i += 1
        j = m
        while j < n and cs[j] == cs[n - j - 1]:
            if i >= n:
                return '-1'
            cs[i], cs[j] = (cs[j], cs[i])
            i, j = (i + 1, j + 1)
    return ''.join(cs)
