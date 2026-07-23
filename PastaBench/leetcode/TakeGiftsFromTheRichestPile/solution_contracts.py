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

def pickGifts(gifts: List[int], k: int) -> int:
    Requires(k >= 0)
    h = [-v for v in gifts]
    heapify(h)
    for _ in range(k):
        Invariant(len(h) > 0)
        heapreplace(h, -int(sqrt(-h[0])))
    return -sum(h)