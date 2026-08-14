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
    Requires(len(mat) > 0)
    Requires(len(mat[0]) > 0)
    Requires(all(len(row) == len(mat[0]) for row in mat))

    # The result [i, j] must be a peak: mat[i][j] is not smaller than its four neighbors.
    # The return value construction ensures mat[i][j] is max in its row (handles left/right).
    Ensures(mat[Result()[0]][Result()[1]] == max(mat[Result()[0]]))
    # These ensure it's a peak with respect to top/bottom neighbors.
    Ensures(Implies(Result()[0] > 0, mat[Result()[0]][Result()[1]] >= mat[Result()[0] - 1][Result()[1]]))
    Ensures(Implies(Result()[0] < len(mat) - 1, mat[Result()[0]][Result()[1]] >= mat[Result()[0] + 1][Result()[1]]))

    l, r = (0, len(mat) - 1)
    while l < r:
        Invariant(0 <= l <= r < len(mat))
        # The binary search maintains an "uphill" property at the boundaries of the search space [l, r].
        # If l>0, there's an upward slope from the max of row l-1 into row l.
        Invariant(l == 0 or mat[l-1][mat[l-1].index(max(mat[l-1]))] <= mat[l][mat[l-1].index(max(mat[l-1]))])
        # If r<N-1, there's a downward slope from the max of row r to row r+1.
        Invariant(r == len(mat) - 1 or mat[r][mat[r].index(max(mat[r]))] > mat[r+1][mat[r].index(max(mat[r]))])
        Decreases(r - l)

        mid = l + r >> 1
        j = mat[mid].index(max(mat[mid]))
        Assert(mat[mid][j] == max(mat[mid]))

        if mat[mid][j] > mat[mid + 1][j]:
            # Peak candidate is in the upper half.
            r = mid
        else:
            # Peak candidate is in the lower half.
            l = mid + 1
    return [l, mat[l].index(max(mat[l]))]