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

def findTheDifference(s: str, t: str) -> str:
    cnt = Counter(s)
    for c in t:
        cnt[c] -= 1
        if cnt[c] < 0:
            return c
