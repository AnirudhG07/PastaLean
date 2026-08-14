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

def numTimesAllBlue(flips: List[int]) -> int:
    ans = mx = 0
    for i, x in enumerate(flips, 1):
        mx = max(mx, x)
        ans += mx == i
    return ans
