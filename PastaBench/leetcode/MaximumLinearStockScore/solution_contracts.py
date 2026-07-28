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

def maxScore(prices: List[int]) -> int:
    Requires(len(prices) > 0)
    cnt = Counter()
    for i, x in enumerate(prices):
        cnt[x - i] += x
    return max(cnt.values())