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

def longestSemiRepetitiveSubstring(s: str) -> int:
    ans, n = (1, len(s))
    cnt = j = 0
    for i in range(1, n):
        cnt += s[i] == s[i - 1]
        while cnt > 1:
            cnt -= s[j] == s[j + 1]
            j += 1
        ans = max(ans, i - j + 1)
    return ans
