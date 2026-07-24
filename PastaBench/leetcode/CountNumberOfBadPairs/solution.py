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

def countBadPairs(nums: List[int]) -> int:
    cnt = Counter()
    ans = 0
    for i, x in enumerate(nums):
        ans += i - cnt[i - x]
        cnt[i - x] += 1
    return ans
