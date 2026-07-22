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

def putMarbles(weights: List[int], k: int) -> int:
    arr = sorted((a + b for a, b in pairwise(weights)))
    return sum(arr[len(arr) - k + 1:]) - sum(arr[:k - 1])
