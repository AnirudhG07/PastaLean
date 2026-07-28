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

def maximumNumberOfOnes(width: int, height: int, sideLength: int, maxOnes: int) -> int:
    x = sideLength
    cnt = [0] * (x * x)
    for i in range(width):
        for j in range(height):
            k = i % x * x + j % x
            cnt[k] += 1
    cnt.sort(reverse=True)
    return sum(cnt[:maxOnes])
