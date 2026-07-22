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

def valueAfterKSeconds(n: int, k: int) -> int:
    a = [1] * n
    mod = 10 ** 9 + 7
    for _ in range(k):
        for i in range(1, n):
            a[i] = (a[i] + a[i - 1]) % mod
    return a[n - 1]
