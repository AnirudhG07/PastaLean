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

def sortTheStudents(score: List[List[int]], k: int) -> List[List[int]]:
    Requires(k >= 0)
    Requires(all(k < len(row) for row in score))

    Ensures(len(Result()) == len(score))
    # The result is a permutation of the input `score`.
    # Using Counter equality is a robust way to check for multiset equality.
    # We map rows to tuples because lists are not hashable.
    Ensures(Counter(map(tuple, Result())) == Counter(map(tuple, score)))
    # The result is sorted in descending order according to the k-th column.
    Ensures(all(Result()[i][k] >= Result()[i+1][k] for i in range(len(Result()) - 1)))

    return sorted(score, key=lambda x: -x[k])