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

def magicalString(n: int) -> int:
    Requires(n >= 0)
    s = [1, 2, 2]
    i = 2
    while len(s) < n:
        Invariant(0 <= i)
        Invariant(i < len(s))
        pre = s[-1]
        cur = 3 - pre
        s += [cur] * s[i]
        i += 1
    Assert(len(s) >= n)
    return s[:n].count(1)