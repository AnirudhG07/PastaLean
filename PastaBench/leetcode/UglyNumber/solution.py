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

def isUgly(n: int) -> bool:
    if n < 1:
        return False
    for x in [2, 3, 5]:
        while n % x == 0:
            n //= x
    return n == 1
