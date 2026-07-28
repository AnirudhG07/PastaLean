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

def makeSubKSumEqual(arr: List[int], k: int) -> int:
    n = len(arr)
    g = gcd(n, k)
    ans = 0
    for i in range(g):
        t = sorted(arr[i:n:g])
        mid = t[len(t) >> 1]
        ans += sum((abs(x - mid) for x in t))
    return ans
