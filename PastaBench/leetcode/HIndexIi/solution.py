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

def hIndex(citations: List[int]) -> int:
    n = len(citations)
    left, right = (0, n)
    while left < right:
        mid = left + right + 1 >> 1
        if citations[n - mid] >= mid:
            left = mid
        else:
            right = mid - 1
    return left
