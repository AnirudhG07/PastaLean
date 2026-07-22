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

def equalPairs(grid: List[List[int]]) -> int:
    n = len(grid)
    ans = 0
    for i in range(n):
        for j in range(n):
            ans += all((grid[i][k] == grid[k][j] for k in range(n)))
    return ans
