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

def minimumSum(n: int, k: int) -> int:
    s, i = (0, 1)
    vis = set()
    for _ in range(n):
        while i in vis:
            i += 1
        vis.add(k - i)
        s += i
        i += 1
    return s
