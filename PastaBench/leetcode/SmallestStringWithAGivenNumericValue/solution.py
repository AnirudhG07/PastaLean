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

def getSmallestString(n: int, k: int) -> str:
    ans = ['a'] * n
    i, d = (n - 1, k - n)
    while d > 25:
        ans[i] = 'z'
        d -= 25
        i -= 1
    ans[i] = chr(ord(ans[i]) + d)
    return ''.join(ans)
