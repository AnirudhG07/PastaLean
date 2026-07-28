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

def countLetters(s: str) -> int:
    n = len(s)
    i = ans = 0
    while i < n:
        j = i
        while j < n and s[j] == s[i]:
            j += 1
        ans += (1 + j - i) * (j - i) // 2
        i = j
    return ans
