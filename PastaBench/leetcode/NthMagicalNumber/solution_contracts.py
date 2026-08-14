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


def nthMagicalNumber(n: int, a: int, b: int) -> int:
    Requires(n >= 1)
    Requires(a >= 1)
    Requires(b >= 1)
    mod = 10**9 + 7
    # If one of a or b divides the other, the set of magical numbers
    # is simply the set of multiples of the smaller of the two.
    # In this case, the n-th magical number is `n * min(a, b)`.
    Ensures(a % b != 0 and b % a != 0 or Result() == (n * min(a, b)) % mod)
    # The modulo operation ensures the result is in a specific range.
    Ensures(0 <= Result() < mod)
    c = lcm(a, b)
    r = (a + b) * n
    return bisect_left(range(r), x=n, key=lambda x: x // a + x // b - x // c) % mod