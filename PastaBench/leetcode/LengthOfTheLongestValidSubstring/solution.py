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

def longestValidSubstring(word: str, forbidden: List[str]) -> int:
    s = set(forbidden)
    ans = i = 0
    for j in range(len(word)):
        for k in range(j, max(j - 10, i - 1), -1):
            if word[k:j + 1] in s:
                i = k + 1
                break
        ans = max(ans, j - i + 1)
    return ans
