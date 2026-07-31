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

def scheduleCourse(courses: List[List[int]]) -> int:
    courses.sort(key=lambda x: x[1])
    pq = []
    s = 0
    for duration, last in courses:
        heappush(pq, -duration)
        s += duration
        while s > last:
            s += heappop(pq)
    return len(pq)
