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

def kthLuckyNumber(k: int) -> str:
    n = 1
    while k > 1 << n:
        k -= 1 << n
        n += 1
    ans = []
    while n:
        n -= 1
        if k <= 1 << n:
            ans.append('4')
        else:
            ans.append('7')
            k -= 1 << n
    return ''.join(ans)
