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

def numberOfSpecialSubstrings(s: str) -> int:
    cnt = Counter()
    ans = j = 0
    for i, c in enumerate(s):
        cnt[c] += 1
        while cnt[c] > 1:
            cnt[s[j]] -= 1
            j += 1
        ans += i - j + 1
    return ans
