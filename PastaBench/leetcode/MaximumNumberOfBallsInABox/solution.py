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

def countBalls(lowLimit: int, highLimit: int) -> int:
    cnt = [0] * 50
    for x in range(lowLimit, highLimit + 1):
        y = 0
        while x:
            y += x % 10
            x //= 10
        cnt[y] += 1
    return max(cnt)
