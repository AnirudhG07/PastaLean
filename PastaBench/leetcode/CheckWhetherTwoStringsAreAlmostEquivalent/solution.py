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

def checkAlmostEquivalent(word1: str, word2: str) -> bool:
    cnt = Counter(word1)
    for c in word2:
        cnt[c] -= 1
    return all((abs(x) <= 3 for x in cnt.values()))
