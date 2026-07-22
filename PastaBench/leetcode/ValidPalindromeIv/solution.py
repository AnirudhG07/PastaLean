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

def makePalindrome(s: str) -> bool:
    i, j = (0, len(s) - 1)
    cnt = 0
    while i < j:
        cnt += s[i] != s[j]
        i, j = (i + 1, j - 1)
    return cnt <= 2
