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
inf = float('inf')

def maximumEnergy(energy: List[int], k: int) -> int:
    Requires(len(energy) > 0)
    Requires(k > 0)
    Requires(k <= len(energy))
    ans = -inf
    n = len(energy)
    for i in range(n - k, n):
        Invariant(0 <= i)
        Invariant(i < n)
        j, s = (i, 0)
        while j >= 0:
            Invariant(0 <= j)
            Invariant(j < n)
            Decreases(j + 1)
            s += energy[j]
            ans = max(ans, s)
            j -= k
    return ans