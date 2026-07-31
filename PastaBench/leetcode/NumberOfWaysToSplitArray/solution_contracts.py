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

def waysToSplitArray(nums: List[int]) -> int:
    Requires(len(nums) >= 2)
    Ensures(0 <= Result())
    Ensures(Result() <= len(nums) - 1)
    s = sum(nums)
    ans = t = 0
    for x in nums[:-1]:
        Invariant(s == sum(nums))
        Invariant(ans >= 0)
        t += x
        ans += t >= s - t
    return ans