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

def isReachableAtTime(sx: int, sy: int, fx: int, fy: int, t: int) -> bool:
    if sx == fx and sy == fy:
        return t != 1
    dx = abs(sx - fx)
    dy = abs(sy - fy)
    return max(dx, dy) <= t
