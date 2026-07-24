from contracts import *
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

def minNumberOperations(target: List[int]) -> int:
    Requires(len(target) > 0)
    Ensures(
        Result() ==
        target[0] +
        sum(max(0, target[i] - target[i - 1]) for i in range(1, len(target)))
    )
    return target[0] + sum((max(0, b - a) for a, b in pairwise(target)))