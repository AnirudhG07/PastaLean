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

def nthMagicalNumber(n: int, a: int, b: int) -> int:
    mod = 10 ** 9 + 7
    c = lcm(a, b)
    r = (a + b) * n
    return bisect_left(range(r), x=n, key=lambda x: x // a + x // b - x // c) % mod
