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

def countSubstrings(s: str, c: str) -> int:
    cnt = s.count(c)
    return cnt + cnt * (cnt - 1) // 2
