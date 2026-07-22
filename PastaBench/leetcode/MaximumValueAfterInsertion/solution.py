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

def maxValue(n: str, x: int) -> str:
    i = 0
    if n[0] == '-':
        i += 1
        while i < len(n) and int(n[i]) <= x:
            i += 1
    else:
        while i < len(n) and int(n[i]) >= x:
            i += 1
    return n[:i] + str(x) + n[i:]
