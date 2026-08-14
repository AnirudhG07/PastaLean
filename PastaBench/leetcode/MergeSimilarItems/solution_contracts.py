from contracts import *
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
    Requires(all(len(item) == 2 and item[0] > 0 and item[1] > 0 for item in items1))
    Requires(len({item[0] for item in items1}) == len(items1))
    Requires(all(len(item) == 2 and item[0] > 0 and item[1] > 0 for item in items2))
    Requires(len({item[0] for item in items2}) == len(items2))

    # The result is sorted by value, which implies values are unique.
    Ensures(all(Result()[i][0] < Result()[i+1][0] for i in range(len(Result()) - 1)))

    # The set of values in the result is the union of the values from the inputs.
    Ensures({item[0] for item in Result()} == {item[0] for item in items1} | {item[0] for item in items2})

    # The weight of each value in the result is the sum of its weights in the inputs.
    Ensures(all(
        item[1] == {v: w for v, w in items1}.get(item[0], 0) + {v: w for v, w in items2}.get(item[0], 0)
        for item in Result()
    ))

    cnt = Counter()
    for v, w in chain(items1, items2):
        cnt[v] += w
    return sorted(cnt.items())