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

def magicalString(n: int) -> int:
    s = [1, 2, 2]
    i = 2
    while len(s) < n:
        pre = s[-1]
        cur = 3 - pre
        s += [cur] * s[i]
        i += 1
    return s[:n].count(1)
