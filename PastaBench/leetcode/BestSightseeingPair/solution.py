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

def maxScoreSightseeingPair(values: List[int]) -> int:
    ans = mx = 0
    for j, x in enumerate(values):
        ans = max(ans, mx + x - j)
        mx = max(mx, x + j)
    return ans
