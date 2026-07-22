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

def replaceNonCoprimes(nums: List[int]) -> List[int]:
    stk = []
    for x in nums:
        stk.append(x)
        while len(stk) > 1:
            x, y = stk[-2:]
            g = gcd(x, y)
            if g == 1:
                break
            stk.pop()
            stk[-1] = x * y // g
    return stk
