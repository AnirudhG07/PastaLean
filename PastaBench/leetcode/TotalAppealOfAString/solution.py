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

def appealSum(s: str) -> int:
    ans = t = 0
    pos = [-1] * 26
    for i, c in enumerate(s):
        c = ord(c) - ord('a')
        t += i - pos[c]
        ans += t
        pos[c] = i
    return ans
