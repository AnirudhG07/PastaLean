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

def numberOfSteps(num: int) -> int:
    ans = 0
    while num:
        if num & 1:
            num -= 1
        else:
            num >>= 1
        ans += 1
    return ans
