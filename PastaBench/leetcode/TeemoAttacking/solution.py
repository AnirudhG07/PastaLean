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

def findPoisonedDuration(timeSeries: List[int], duration: int) -> int:
    ans = duration
    for a, b in pairwise(timeSeries):
        ans += min(duration, b - a)
    return ans
