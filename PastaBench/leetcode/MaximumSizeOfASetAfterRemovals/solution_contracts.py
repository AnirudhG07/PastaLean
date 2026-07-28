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

def maximumSetSize(nums1: List[int], nums2: List[int]) -> int:
    # Computes the maximum number of distinct elements obtainable by
    # taking at most len(nums1)//2 unique elements from nums1 only,
    # at most len(nums1)//2 unique elements from nums2 only,
    # and including all elements common to both, without exceeding len(nums1).
    Ensures(0 <= Result() <= len(nums1))
    s1 = set(nums1)
    s2 = set(nums2)
    n = len(nums1)
    a = min(len(s1 - s2), n // 2)
    b = min(len(s2 - s1), n // 2)
    return min(a + b + len(s1 & s2), n)