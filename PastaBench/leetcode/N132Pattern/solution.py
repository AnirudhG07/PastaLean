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
inf = float('inf')

def find132pattern(nums: List[int]) -> bool:
    vk = -inf
    stk = []
    for x in nums[::-1]:
        if x < vk:
            return True
        while stk and stk[-1] < x:
            vk = stk.pop()
        stk.append(x)
    return False
