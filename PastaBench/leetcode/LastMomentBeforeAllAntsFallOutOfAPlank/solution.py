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

def getLastMoment(n: int, left: List[int], right: List[int]) -> int:
    ans = 0
    for x in left:
        ans = max(ans, x)
    for x in right:
        ans = max(ans, n - x)
    return ans
