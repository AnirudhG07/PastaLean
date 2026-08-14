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

def numRescueBoats(people: List[int], limit: int) -> int:
    people.sort()
    ans = 0
    i, j = (0, len(people) - 1)
    while i <= j:
        if people[i] + people[j] <= limit:
            i += 1
        j -= 1
        ans += 1
    return ans
