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

def addToArrayForm(num: List[int], k: int) -> List[int]:
    ans = []
    i = len(num) - 1
    while i >= 0 or k:
        k += 0 if i < 0 else num[i]
        k, x = divmod(k, 10)
        ans.append(x)
        i -= 1
    return ans[::-1]
