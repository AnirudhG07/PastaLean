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

def distributeCandies(candies: int, num_people: int) -> List[int]:
    ans = [0] * num_people
    i = 0
    while candies:
        ans[i % num_people] += min(candies, i + 1)
        candies -= min(candies, i + 1)
        i += 1
    return ans
