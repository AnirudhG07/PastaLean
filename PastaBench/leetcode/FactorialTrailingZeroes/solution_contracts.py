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

def trailingZeroes(n: int) -> int:
    Requires(n >= 0)
    orig = n
    Ensures(Result() == sum(orig // (5**k) for k in range(1, orig + 1)))
    ans = 0
    i = 0
    while n:
        Invariant(i >= 0)
        Invariant(n >= 0)
        Invariant(ans == sum(orig // (5**j) for j in range(1, i + 1)))
        Invariant(n == orig // (5**i))
        Decreases(n)
        n //= 5
        ans += n
        i += 1
    Assert(ans == sum(orig // (5**k) for k in range(1, orig + 1)))
    return ans