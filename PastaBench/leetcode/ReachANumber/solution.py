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

def reachNumber(target: int) -> int:
    target = abs(target)
    s = k = 0
    while 1:
        if s >= target and (s - target) % 2 == 0:
            return k
        k += 1
        s += k
