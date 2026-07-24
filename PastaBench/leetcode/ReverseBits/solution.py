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

def reverseBits(n: int) -> int:
    ans = 0
    for i in range(32):
        ans |= (n & 1) << 31 - i
        n >>= 1
    return ans
