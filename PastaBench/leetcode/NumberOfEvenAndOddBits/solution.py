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

def evenOddBit(n: int) -> List[int]:
    ans = [0, 0]
    i = 0
    while n:
        ans[i] += n & 1
        i ^= 1
        n >>= 1
    return ans
