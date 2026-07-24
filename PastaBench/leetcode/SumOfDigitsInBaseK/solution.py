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

def sumBase(n: int, k: int) -> int:
    ans = 0
    while n:
        ans += n % k
        n //= k
    return ans
