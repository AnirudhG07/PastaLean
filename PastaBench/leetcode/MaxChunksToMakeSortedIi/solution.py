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

def maxChunksToSorted(arr: List[int]) -> int:
    stk = []
    for v in arr:
        if not stk or v >= stk[-1]:
            stk.append(v)
        else:
            mx = stk.pop()
            while stk and stk[-1] > v:
                stk.pop()
            stk.append(mx)
    return len(stk)
