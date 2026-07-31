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


def getNoZeroIntegers(n: int) -> List[int]:
    Requires(n >= 2)
    Ensures(len(Result()) == 2)
    Ensures(Result()[0] > 0)
    Ensures(Result()[1] > 0)
    Ensures(Result()[0] + Result()[1] == n)
    Ensures('0' not in str(Result()[0]))
    Ensures('0' not in str(Result()[1]))

    for a in range(1, n):
        Invariant(1 <= a < n)
        Decreases(n - a)

        b = n - a
        Assert(a + b == n)
        Assert(a > 0 and b > 0)

        if '0' not in str(a) + str(b):
            return [a, b]