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

def reconstructQueue(people: List[List[int]]) -> List[List[int]]:
    people.sort(key=lambda x: (-x[0], x[1]))
    ans = []
    for p in people:
        ans.insert(p[1], p)
    return ans
