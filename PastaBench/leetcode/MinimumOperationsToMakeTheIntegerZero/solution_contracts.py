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

def makeTheIntegerZero(num1: int, num2: int) -> int:
    Requires(1 <= num1 <= 10**9)
    Requires(-10**9 <= num2 <= 10**9)
    Ensures(Result() == -1 or (
        Result() >= 1 and
        (num1 - Result() * num2) >= 0 and
        (num1 - Result() * num2).bit_count() <= Result() and
        Result() <= (num1 - Result() * num2)
    ))
    for k in count(1):
        Invariant(k >= 1)
        x = num1 - k * num2
        if x < 0:
            break
        if x.bit_count() <= k <= x:
            return k
    return -1