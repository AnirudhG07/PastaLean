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

def maximumCandies(candies: List[int], k: int) -> int:
    l, r = (0, max(candies))
    while l < r:
        mid = l + r + 1 >> 1
        if sum((x // mid for x in candies)) >= k:
            l = mid
        else:
            r = mid - 1
    return l
