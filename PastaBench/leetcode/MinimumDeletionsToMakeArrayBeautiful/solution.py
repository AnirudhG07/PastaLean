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

def minDeletion(nums: List[int]) -> int:
    n = len(nums)
    i = ans = 0
    while i < n - 1:
        if nums[i] == nums[i + 1]:
            ans += 1
            i += 1
        else:
            i += 2
    ans += (n - ans) % 2
    return ans
