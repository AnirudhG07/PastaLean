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

def numIdenticalPairs(nums: List[int]) -> int:
    ans = 0
    cnt = Counter()
    for x in nums:
        ans += cnt[x]
        cnt[x] += 1
    return ans
