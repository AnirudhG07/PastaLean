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
from contracts import *

def maximumNumberOfOnes(width: int, height: int, sideLength: int, maxOnes: int) -> int:
    Requires(width > 0)
    Requires(height > 0)
    Requires(sideLength > 0)
    Requires(0 <= maxOnes)
    Requires(maxOnes <= sideLength * sideLength)

    Ensures(Result() >= 0)
    Ensures(Result() <= width * height)

    x = sideLength
    cnt = [0] * (x * x)
    Assert(len(cnt) == x * x)
    Assert(all(c == 0 for c in cnt))

    for i in range(width):
        Invariant(0 <= i <= width)
        Invariant(len(cnt) == x * x)
        Invariant(all(c >= 0 for c in cnt))
        Invariant(sum(cnt) == i * height)
        for j in range(height):
            Invariant(0 <= j <= height)
            Invariant(len(cnt) == x * x)
            Invariant(all(c >= 0 for c in cnt))
            Invariant(sum(cnt) == i * height + j)
            k = i % x * x + j % x
            Assert(0 <= k < x * x)
            cnt[k] += 1

    Assert(sum(cnt) == width * height)
    Assert(all(c >= 0 for c in cnt))

    cnt.sort(reverse=True)

    Assert(sum(cnt) == width * height)
    Assert(all(c >= 0 for c in cnt))

    return sum(cnt[:maxOnes])