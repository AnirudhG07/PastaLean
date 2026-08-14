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

def maximumGroups(grades: List[int]) -> int:
    n = len(grades)
    return bisect_right(range(n + 1), n * 2, key=lambda x: x * x + x) - 1
