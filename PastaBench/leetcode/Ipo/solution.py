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

def findMaximizedCapital(k: int, w: int, profits: List[int], capital: List[int]) -> int:
    h1 = [(c, p) for c, p in zip(capital, profits)]
    heapify(h1)
    h2 = []
    while k:
        while h1 and h1[0][0] <= w:
            heappush(h2, -heappop(h1)[1])
        if not h2:
            break
        w -= heappop(h2)
        k -= 1
    return w
