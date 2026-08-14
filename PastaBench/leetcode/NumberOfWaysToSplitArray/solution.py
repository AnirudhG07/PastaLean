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
    s = sum(nums)
    ans = t = 0
    for x in nums[:-1]:
        t += x
        ans += t >= s - t
    return ans
