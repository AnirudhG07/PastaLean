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

def countPairs(nums: List[int], k: int) -> int:
    ans = 0
    for j in range(1, len(nums)):
        for i, x in enumerate(nums[:j]):
            ans += int(x == nums[j] and i * j % k == 0)
    return ans
