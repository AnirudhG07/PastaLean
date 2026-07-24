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

def countTriplets(nums: List[int]) -> int:
    cnt = Counter((x & y for x in nums for y in nums))
    return sum((v for xy, v in cnt.items() for z in nums if xy & z == 0))
