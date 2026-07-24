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

def reverseBits(n: int) -> int:
    Requires(0 <= n < 2**32)
    orig = n
    Ensures(Result() == sum(((orig >> j) & 1) << (31 - j) for j in range(32)))
    ans = 0
    for i in range(32):
        Invariant(0 <= i)
        Invariant(i <= 32)
        Invariant(n == orig >> i)
        Invariant(ans == sum(((orig >> j) & 1) << (31 - j) for j in range(i)))
        ans |= (n & 1) << (31 - i)
        n >>= 1
    Assert(ans == sum(((orig >> j) & 1) << (31 - j) for j in range(32)))
    return ans