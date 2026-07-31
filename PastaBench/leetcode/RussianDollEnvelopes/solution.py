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

def maxEnvelopes(envelopes: List[List[int]]) -> int:
    envelopes.sort(key=lambda x: (x[0], -x[1]))
    d = [envelopes[0][1]]
    for _, h in envelopes[1:]:
        if h > d[-1]:
            d.append(h)
        else:
            idx = bisect_left(d, h)
            d[idx] = h
    return len(d)
