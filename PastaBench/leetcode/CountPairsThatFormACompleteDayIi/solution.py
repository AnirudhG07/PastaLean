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

def countCompleteDayPairs(hours: List[int]) -> int:
    cnt = Counter()
    ans = 0
    for x in hours:
        ans += cnt[(24 - x % 24) % 24]
        cnt[x % 24] += 1
    return ans
