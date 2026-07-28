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


def computeArea(ax1: int, ay1: int, ax2: int, ay2: int, bx1: int, by1: int, bx2: int, by2: int) -> int:
    Requires(ax2 >= ax1)
    Requires(ay2 >= ay1)
    Requires(bx2 >= bx1)
    Requires(by2 >= by1)
    # The combined area is at least each rectangle's area...
    Ensures(Result() >= (ax2 - ax1) * (ay2 - ay1))
    Ensures(Result() >= (bx2 - bx1) * (by2 - by1))
    # ...and at most the sum of both areas
    Ensures(Result() <= (ax2 - ax1) * (ay2 - ay1) + (bx2 - bx1) * (by2 - by1))
    a = (ax2 - ax1) * (ay2 - ay1)
    b = (bx2 - bx1) * (by2 - by1)
    width = min(ax2, bx2) - max(ax1, bx1)
    height = min(ay2, by2) - max(ay1, by1)
    return a + b - max(height, 0) * max(width, 0)