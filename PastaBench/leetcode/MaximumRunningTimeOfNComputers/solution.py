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

def maxRunTime(n: int, batteries: List[int]) -> int:
    l, r = (0, sum(batteries))
    while l < r:
        mid = l + r + 1 >> 1
        if sum((min(x, mid) for x in batteries)) >= n * mid:
            l = mid
        else:
            r = mid - 1
    return l
