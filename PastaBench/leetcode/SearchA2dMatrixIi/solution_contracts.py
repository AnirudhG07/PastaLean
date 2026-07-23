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

def searchMatrix(matrix: List[List[int]], target: int) -> bool:
    for row in matrix:
        j = bisect_left(row, target)
        if j < len(matrix[0]) and row[j] == target:
            Assert(target in row)    # ← the point: if we return True, the target really is in this row
            return True
    return False