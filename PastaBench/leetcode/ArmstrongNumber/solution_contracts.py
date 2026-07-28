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

def isArmstrong(n: int) -> bool:
    Requires(n >= 0)
    k = len(str(n))
    s, x = 0, n
    while x:
        Invariant(x >= 0)
        Decreases(x)
        s += (x % 10) ** k
        x //= 10
    return s == n