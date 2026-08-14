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

def minimizedMaximum(n: int, quantities: List[int]) -> int:

    def check(x):
        return sum(((v + x - 1) // x for v in quantities)) <= n
    return 1 + bisect_left(range(1, 10 ** 6), True, key=check)
