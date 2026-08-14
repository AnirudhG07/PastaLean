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

def lengthOfLIS(nums: List[int]) -> int:
    n = len(nums)
    f = [1] * n
    for i in range(1, n):
        for j in range(i):
            if nums[j] < nums[i]:
                f[i] = max(f[i], f[j] + 1)
    return max(f)
