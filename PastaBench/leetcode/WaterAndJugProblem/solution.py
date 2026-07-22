import heapq
import itertools
from sortedcontainers import SortedList
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

def canMeasureWater(x: int, y: int, target: int) -> bool:
    if target == 0:
        return True
    if x + y < target:
        return False
    g = math.gcd(x, y)
    return target % g == 0
