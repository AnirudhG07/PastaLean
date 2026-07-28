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

def dailyTemperatures(temperatures: List[int]) -> List[int]:
    stk = []
    n = len(temperatures)
    ans = [0] * n
    for i in range(n - 1, -1, -1):
        while stk and temperatures[stk[-1]] <= temperatures[i]:
            stk.pop()
        if stk:
            ans[i] = stk[-1] - i
        stk.append(i)
    return ans
