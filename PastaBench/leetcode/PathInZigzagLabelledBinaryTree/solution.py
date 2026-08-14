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

def pathInZigZagTree(label: int) -> List[int]:
    x = i = 1
    while x << 1 <= label:
        x <<= 1
        i += 1
    ans = [0] * i
    while i:
        ans[i - 1] = label
        label = (1 << i - 1) + (1 << i) - 1 - label >> 1
        i -= 1
    return ans
