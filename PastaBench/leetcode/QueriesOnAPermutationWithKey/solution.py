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

def processQueries(queries: List[int], m: int) -> List[int]:
    p = list(range(1, m + 1))
    ans = []
    for v in queries:
        j = p.index(v)
        ans.append(j)
        p.pop(j)
        p.insert(0, v)
    return ans
