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

def hIndex(citations: List[int]) -> int:
    citations.sort(reverse=True)
    for h in range(len(citations), 0, -1):
        if citations[h - 1] >= h:
            return h
    return 0
