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

def isPowerOfThree(n: int) -> bool:
    # The intent: return True exactly when n is a (non‐negative) power of three.
    Requires(n >= 1)
    orig = n
    Ensures(Result() == any(orig == 3**k for k in range(0, orig.bit_length() + 1)))
    while n > 2:
        if n % 3:
            return False
        n //= 3
    return n == 1