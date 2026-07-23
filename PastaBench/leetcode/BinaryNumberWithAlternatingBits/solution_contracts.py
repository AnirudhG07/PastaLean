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


def hasAlternatingBits(n: int) -> bool:
    Requires(n >= 0)
    prev = -1
    while n:
        Decreases(n)
        curr = n & 1
        if prev == curr:
            return False
        prev = curr
        n >>= 1
    return True