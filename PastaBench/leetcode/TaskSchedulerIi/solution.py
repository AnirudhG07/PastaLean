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

def taskSchedulerII(tasks: List[int], space: int) -> int:
    day = defaultdict(int)
    ans = 0
    for task in tasks:
        ans += 1
        ans = max(ans, day[task])
        day[task] = ans + space + 1
    return ans
