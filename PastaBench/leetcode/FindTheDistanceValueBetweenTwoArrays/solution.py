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

def findTheDistanceValue(arr1: List[int], arr2: List[int], d: int) -> int:
    arr2.sort()
    ans = 0
    for x in arr1:
        i = bisect_left(arr2, x - d)
        ans += i == len(arr2) or arr2[i] > x + d
    return ans
