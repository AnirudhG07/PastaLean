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

def earliestFullBloom(plantTime: List[int], growTime: List[int]) -> int:
    ans = t = 0
    for pt, gt in sorted(zip(plantTime, growTime), key=lambda x: -x[1]):
        t += pt
        ans = max(ans, t + gt)
    return ans
