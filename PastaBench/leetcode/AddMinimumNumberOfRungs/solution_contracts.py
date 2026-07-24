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

def addRungs(rungs: List[int], dist: int) -> int:
    Requires(dist > 0)
    # Ensure gaps between successive rungs (including ground 0) are at least 1
    Requires(all(b - a >= 1 for a, b in pairwise([0] + rungs)))
    # The number of added rungs is non-negative
    Ensures(Result() >= 0)
    rungs = [0] + rungs
    return sum(((b - a - 1) // dist for a, b in pairwise(rungs)))