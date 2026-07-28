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

def minimumBoxes(n: int) -> int:
    s, k = (0, 1)
    while s + k * (k + 1) // 2 <= n:
        s += k * (k + 1) // 2
        k += 1
    k -= 1
    ans = k * (k + 1) // 2
    k = 1
    while s < n:
        ans += 1
        s += k
        k += 1
    return ans
