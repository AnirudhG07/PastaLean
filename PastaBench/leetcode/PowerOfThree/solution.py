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

def isPowerOfThree(n: int) -> bool:
    while n > 2:
        if n % 3:
            return False
        n //= 3
    return n == 1
