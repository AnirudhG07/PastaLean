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

def mergeSimilarItems(items1: List[List[int]], items2: List[List[int]]) -> List[List[int]]:
    cnt = Counter()
    for v, w in chain(items1, items2):
        cnt[v] += w
    return sorted(cnt.items())
