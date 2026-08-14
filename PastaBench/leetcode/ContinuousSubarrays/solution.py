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

def continuousSubarrays(nums: List[int]) -> int:
    ans = i = 0
    sl = SortedList()
    for x in nums:
        sl.add(x)
        while sl[-1] - sl[0] > 2:
            sl.remove(nums[i])
            i += 1
        ans += len(sl)
    return ans
