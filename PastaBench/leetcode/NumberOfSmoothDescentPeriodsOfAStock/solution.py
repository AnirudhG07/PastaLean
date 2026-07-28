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

def getDescentPeriods(prices: List[int]) -> int:
    ans = 0
    i, n = (0, len(prices))
    while i < n:
        j = i + 1
        while j < n and prices[j - 1] - prices[j] == 1:
            j += 1
        cnt = j - i
        ans += (1 + cnt) * cnt // 2
        i = j
    return ans
