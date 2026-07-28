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

def closestToTarget(arr: List[int], target: int) -> int:
    ans = abs(arr[0] - target)
    s = {arr[0]}
    for x in arr:
        s = {x & y for y in s} | {x}
        ans = min(ans, min((abs(y - target) for y in s)))
    return ans
