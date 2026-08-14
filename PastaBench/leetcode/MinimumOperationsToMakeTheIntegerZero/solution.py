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

def makeTheIntegerZero(num1: int, num2: int) -> int:
    for k in count(1):
        x = num1 - k * num2
        if x < 0:
            break
        if x.bit_count() <= k <= x:
            return k
    return -1
