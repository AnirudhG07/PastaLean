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

def minimumLength(s: str) -> int:
    cnt = Counter(s)
    return sum((1 if x & 1 else 2 for x in cnt.values()))
