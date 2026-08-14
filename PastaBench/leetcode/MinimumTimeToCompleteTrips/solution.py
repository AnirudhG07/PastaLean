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

def minimumTime(time: List[int], totalTrips: int) -> int:
    mx = min(time) * totalTrips
    return bisect_left(range(mx), totalTrips, key=lambda x: sum((x // v for v in time)))
