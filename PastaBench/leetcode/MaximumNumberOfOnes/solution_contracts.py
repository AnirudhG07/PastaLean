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

def maximumNumberOfOnes(width: int, height: int, sideLength: int, maxOnes: int) -> int:
    Requires(width >= 0)
    Requires(height >= 0)
    Requires(sideLength > 0)
    Requires(maxOnes >= 0)

    x = sideLength
    cnt = [0] * (x * x)
    Assert(len(cnt) == x * x)
    for i in range(width):
        Invariant(0 <= i)
        Invariant(i < width)
        for j in range(height):
            Invariant(0 <= j)
            Invariant(j < height)
            k = i % x * x + j % x
            Assert(0 <= k < len(cnt))
            cnt[k] += 1
    cnt.sort(reverse=True)
    return sum(cnt[:maxOnes])