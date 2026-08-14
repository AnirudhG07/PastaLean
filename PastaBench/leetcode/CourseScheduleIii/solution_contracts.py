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
from contracts import *

def scheduleCourse(courses: List[List[int]]) -> int:
    Requires(all(len(c) == 2 and c[0] > 0 and c[1] > 0 for c in courses))
    Ensures(0 <= Result() <= len(courses))

    courses.sort(key=lambda x: x[1])
    Assert(all(courses[i][1] <= courses[i+1][1] for i in range(len(courses) - 1)))
    
    pq = []
    s = 0
    for duration, last in courses:
        Invariant(s >= 0)
        Invariant(0 <= len(pq) <= len(courses))

        heappush(pq, -duration)
        s += duration
        
        while s > last:
            Decreases(s)
            Invariant(s > last)
            Invariant(len(pq) > 0)
            
            s += heappop(pq)
            
        Assert(s <= last)
        
    return len(pq)