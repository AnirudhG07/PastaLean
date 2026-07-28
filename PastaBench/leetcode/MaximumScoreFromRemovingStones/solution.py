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

def maximumScore(a: int, b: int, c: int) -> int:
    s = sorted([a, b, c])
    ans = 0
    while s[1]:
        ans += 1
        s[1] -= 1
        s[2] -= 1
        s.sort()
    return ans
