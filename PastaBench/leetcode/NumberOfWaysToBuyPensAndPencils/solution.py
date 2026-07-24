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

def waysToBuyPensPencils(total: int, cost1: int, cost2: int) -> int:
    ans = 0
    for x in range(total // cost1 + 1):
        y = (total - x * cost1) // cost2 + 1
        ans += y
    return ans
