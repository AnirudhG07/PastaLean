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

def circularGameLosers(n: int, k: int) -> List[int]:
    vis = [False] * n
    i, p = (0, 1)
    while not vis[i]:
        vis[i] = True
        i = (i + p * k) % n
        p += 1
    return [i + 1 for i in range(n) if not vis[i]]
