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

def digitSum(s: str, k: int) -> str:
    while len(s) > k:
        t = []
        n = len(s)
        for i in range(0, n, k):
            x = 0
            for j in range(i, min(i + k, n)):
                x += int(s[j])
            t.append(str(x))
        s = ''.join(t)
    return s
