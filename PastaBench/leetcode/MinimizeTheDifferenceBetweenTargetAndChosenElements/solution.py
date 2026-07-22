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
    f = {0}
    for row in mat:
        f = set((a + b for a in f for b in row))
    return min((abs(v - target) for v in f))
