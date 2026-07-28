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

def sumOfTheDigitsOfHarshadNumber(x: int) -> int:
    s, y = (0, x)
    while y:
        s += y % 10
        y //= 10
    return s if x % s == 0 else -1
