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

def consecutiveNumbersSum(n: int) -> int:
    n <<= 1
    ans, k = (0, 1)
    while k * (k + 1) <= n:
        if n % k == 0 and (n // k - k + 1) % 2 == 0:
            ans += 1
        k += 1
    return ans
