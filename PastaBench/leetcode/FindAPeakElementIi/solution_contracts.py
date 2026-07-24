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

def findPeakGrid(mat: List[List[int]]) -> List[int]:
    Requires(len(mat) > 0 and all(len(row) == len(mat[0]) and len(mat[0]) > 0 for row in mat))
    l, r = (0, len(mat) - 1)
    while l < r:
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(r < len(mat))
        Decreases(r - l)
        mid = (l + r) >> 1
        Assert(0 <= mid < len(mat))
        j = mat[mid].index(max(mat[mid]))
        Assert(0 <= j < len(mat[mid]))
        if mat[mid][j] > mat[mid + 1][j]:
            r = mid
        else:
            l = mid + 1
    # final row index l is in [0, len(mat))
    return [l, mat[l].index(max(mat[l]))]