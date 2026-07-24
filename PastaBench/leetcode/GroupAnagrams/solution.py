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

def groupAnagrams(strs: List[str]) -> List[List[str]]:
    d = defaultdict(list)
    for s in strs:
        k = ''.join(sorted(s))
        d[k].append(s)
    return list(d.values())
