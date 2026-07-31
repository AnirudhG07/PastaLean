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

def maxHeightOfTriangle(red: int, blue: int) -> int:
    ans = 0
    for k in range(2):
        c = [red, blue]
        i, j = (1, k)
        while i <= c[j]:
            c[j] -= i
            j ^= 1
            ans = max(ans, i)
            i += 1
    return ans
