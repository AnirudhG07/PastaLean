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
    s1 = set(nums1)
    s2 = set(nums2)
    n = len(nums1)
    a = min(len(s1 - s2), n // 2)
    b = min(len(s2 - s1), n // 2)
    return min(a + b + len(s1 & s2), n)
