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

def maxEqualRowsAfterFlips(matrix: List[List[int]]) -> int:
    Requires(len(matrix) > 0)
    Requires(len(matrix[0]) > 0)
    Requires(all(len(row) == len(matrix[0]) for row in matrix))
    Requires(all(cell == 0 or cell == 1 for row in matrix for cell in row))
    Ensures(1 <= Result() <= len(matrix))

    cnt = Counter()
    # We use enumerate to get an index `i` for writing a precise loop invariant.
    # This does not change the runtime behavior.
    for i, row in enumerate(matrix):
        Invariant(0 <= i <= len(matrix))
        # The core invariant: the sum of counts equals the number of rows processed.
        Invariant(sum(cnt.values()) == i)
        # Invariants on the structure of keys in the counter, derived from matrix properties.
        Invariant(all(len(key) == len(matrix[0]) for key in cnt.keys()))
        Invariant(all(x == 0 or x == 1 for key in cnt.keys() for x in key))

        t = tuple(row) if row[0] == 0 else tuple((x ^ 1 for x in row))
        cnt[t] += 1

    # After the loop, the invariant gives us the total sum of counts.
    Assert(sum(cnt.values()) == len(matrix))
    return max(cnt.values())