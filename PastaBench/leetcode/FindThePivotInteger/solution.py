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

def pivotInteger(n: int) -> int:
    for x in range(1, n + 1):
        if (1 + x) * x == (x + n) * (n - x + 1):
            return x
    return -1
