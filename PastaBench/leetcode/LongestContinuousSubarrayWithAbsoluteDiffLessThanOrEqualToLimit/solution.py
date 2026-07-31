import heapq
import itertools
from sortedcontainers import SortedList
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

def longestSubarray(nums: List[int], limit: int) -> int:
    sl = SortedList()
    ans = j = 0
    for i, x in enumerate(nums):
        sl.add(x)
        while sl[-1] - sl[0] > limit:
            sl.remove(nums[j])
            j += 1
        ans = max(ans, i - j + 1)
    return ans
