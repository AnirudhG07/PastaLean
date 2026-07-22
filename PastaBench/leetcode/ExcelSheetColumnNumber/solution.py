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

def titleToNumber(columnTitle: str) -> int:
    ans = 0
    for c in map(ord, columnTitle):
        ans = ans * 26 + c - ord('A') + 1
    return ans
