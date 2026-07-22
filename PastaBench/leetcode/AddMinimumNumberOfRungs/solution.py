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
    rungs = [0] + rungs
    return sum(((b - a - 1) // dist for a, b in pairwise(rungs)))
