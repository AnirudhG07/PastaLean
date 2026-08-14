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

def isPalindrome(x: int) -> bool:
    if x < 0 or (x and x % 10 == 0):
        return False
    y = 0
    while y < x:
        y = y * 10 + x % 10
        x //= 10
    return x in (y, y // 10)
