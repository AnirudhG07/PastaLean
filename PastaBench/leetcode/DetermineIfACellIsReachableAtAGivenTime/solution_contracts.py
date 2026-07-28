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
from contracts import *

def isReachableAtTime(sx: int, sy: int, fx: int, fy: int, t: int) -> bool:
    Ensures(Result() == ((sx == fx and sy == fy and t != 1)
                         or ((sx != fx or sy != fy)
                             and max(abs(sx - fx), abs(sy - fy)) <= t)))
    if sx == fx and sy == fy:
        return t != 1
    dx = abs(sx - fx)
    dy = abs(sy - fy)
    return max(dx, dy) <= t