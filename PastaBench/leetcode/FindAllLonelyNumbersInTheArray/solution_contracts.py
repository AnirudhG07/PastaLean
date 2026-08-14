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

def findLonely(nums: List[int]) -> List[int]:
    Ensures(set(Result()) == {x for x in nums if nums.count(x) == 1 and (x - 1) not in nums and (x + 1) not in nums})
    cnt = Counter(nums)
    return [x for x, v in cnt.items() if v == 1 and cnt[x - 1] == 0 and (cnt[x + 1] == 0)]