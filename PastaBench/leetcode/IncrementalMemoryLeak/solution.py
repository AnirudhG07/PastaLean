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

def memLeak(memory1: int, memory2: int) -> List[int]:
    i = 1
    while i <= max(memory1, memory2):
        if memory1 >= memory2:
            memory1 -= i
        else:
            memory2 -= i
        i += 1
    return [i, memory1, memory2]
