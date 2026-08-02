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
    Requires(len(matrix) == 0 or all(len(row) == len(matrix[0]) for row in matrix))
    Requires(all(all(row[i] <= row[i+1] for i in range(len(row)-1)) for row in matrix))
    Ensures(Result() == any(target in row for row in matrix))
    for row in matrix:
        j = bisect_left(row, target)
        Assert(0 <= j <= len(row))
        if j < len(matrix[0]) and row[j] == target:
            Assert(target in row)
            return True
    Assert(not any(target in row for row in matrix))
    return False