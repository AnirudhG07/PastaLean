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

def numberOfUniqueGoodSubsequences(binary: str) -> int:
    f = g = 0
    ans = 0
    mod = 10 ** 9 + 7
    for c in binary:
        if c == '0':
            g = (g + f) % mod
            ans = 1
        else:
            f = (f + g + 1) % mod
    ans = (ans + f + g) % mod
    return ans
