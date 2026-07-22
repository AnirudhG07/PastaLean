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

def minStoneSum(piles: List[int], k: int) -> int:
    pq = [-x for x in piles]
    heapify(pq)
    for _ in range(k):
        heapreplace(pq, pq[0] // 2)
    return -sum(pq)
