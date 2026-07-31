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

def nextGreaterElement(nums1: List[int], nums2: List[int]) -> List[int]:
    stk = []
    d = {}
    for x in nums2[::-1]:
        while stk and stk[-1] < x:
            stk.pop()
        if stk:
            d[x] = stk[-1]
        stk.append(x)
    return [d.get(x, -1) for x in nums1]
