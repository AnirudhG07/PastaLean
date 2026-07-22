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

def maxLength(ribbons: List[int], k: int) -> int:
    left, right = (0, max(ribbons))
    while left < right:
        mid = left + right + 1 >> 1
        cnt = sum((x // mid for x in ribbons))
        if cnt >= k:
            left = mid
        else:
            right = mid - 1
    return left
