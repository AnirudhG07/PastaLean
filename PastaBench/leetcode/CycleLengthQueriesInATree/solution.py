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

def cycleLengthQueries(n: int, queries: List[List[int]]) -> List[int]:
    ans = []
    for a, b in queries:
        t = 1
        while a != b:
            if a > b:
                a >>= 1
            else:
                b >>= 1
            t += 1
        ans.append(t)
    return ans
