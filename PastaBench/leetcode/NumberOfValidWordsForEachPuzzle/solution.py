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

def findNumOfValidWords(words: List[str], puzzles: List[str]) -> List[int]:
    cnt = Counter()
    for w in words:
        mask = 0
        for c in w:
            mask |= 1 << ord(c) - ord('a')
        cnt[mask] += 1
    ans = []
    for p in puzzles:
        mask = 0
        for c in p:
            mask |= 1 << ord(c) - ord('a')
        x, i, j = (0, ord(p[0]) - ord('a'), mask)
        while j:
            if j >> i & 1:
                x += cnt[j]
            j = j - 1 & mask
        ans.append(x)
    return ans
