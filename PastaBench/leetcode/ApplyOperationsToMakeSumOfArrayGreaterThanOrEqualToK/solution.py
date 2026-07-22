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

def minOperations(k: int) -> int:
    ans = k
    for a in range(k):
        x = a + 1
        b = (k + x - 1) // x - 1
        ans = min(ans, a + b)
    return ans
