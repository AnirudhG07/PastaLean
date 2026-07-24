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

def mostCompetitive(nums: List[int], k: int) -> List[int]:
    Requires(k >= 0)
    Requires(k <= len(nums))
    stk = []
    n = len(nums)
    for i, v in enumerate(nums):
        while stk and stk[-1] > v and (len(stk) + n - i > k):
            stk.pop()
        if len(stk) < k:
            stk.append(v)
    return stk