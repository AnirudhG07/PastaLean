from contracts import *
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

def minimizeTheDifference(mat: List[List[int]], target: int) -> int:
    Requires(all(len(row) > 0 for row in mat))
    Ensures(Result() >= 0)
    f = {0}
    for row in mat:
        Invariant(len(f) > 0)
        f = set(a + b for a in f for b in row)
    return min(abs(v - target) for v in f)