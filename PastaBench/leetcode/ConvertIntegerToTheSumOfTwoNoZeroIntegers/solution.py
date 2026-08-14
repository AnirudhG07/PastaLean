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

def getNoZeroIntegers(n: int) -> List[int]:
    for a in range(1, n):
        b = n - a
        if '0' not in str(a) + str(b):
            return [a, b]
