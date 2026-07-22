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

def circularPermutation(n: int, start: int) -> List[int]:
    g = [i ^ i >> 1 for i in range(1 << n)]
    j = g.index(start)
    return g[j:] + g[:j]
