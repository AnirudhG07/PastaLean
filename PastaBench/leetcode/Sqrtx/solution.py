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

def mySqrt(x: int) -> int:
    l, r = (0, x)
    while l < r:
        mid = l + r + 1 >> 1
        if mid > x // mid:
            r = mid - 1
        else:
            l = mid
    return l
