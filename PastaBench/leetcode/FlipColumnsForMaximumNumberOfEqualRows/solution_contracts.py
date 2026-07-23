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

def maxEqualRowsAfterFlips(matrix: List[List[int]]) -> int:
    Requires(len(matrix) > 0)
    Requires(all(len(row) > 0 for row in matrix))
    cnt = Counter()
    for row in matrix:
        t = tuple(row) if row[0] == 0 else tuple((x ^ 1 for x in row))
        cnt[t] += 1
    return max(cnt.values())