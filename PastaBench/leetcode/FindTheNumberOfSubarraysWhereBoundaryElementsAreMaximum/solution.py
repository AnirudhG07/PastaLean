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

def numberOfSubarrays(nums: List[int]) -> int:
    stk = []
    ans = 0
    for x in nums:
        while stk and stk[-1][0] < x:
            stk.pop()
        if not stk or stk[-1][0] > x:
            stk.append([x, 1])
        else:
            stk[-1][1] += 1
        ans += stk[-1][1]
    return ans
