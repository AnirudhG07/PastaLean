from contracts import *
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
    Requires(memory1 >= 0)
    Requires(memory2 >= 0)
    Ensures(Result()[1] >= 0)
    Ensures(Result()[2] >= 0)
    Ensures(max(Result()[1], Result()[2]) < Result()[0])
    i = 1
    while i <= max(memory1, memory2):
        Invariant(memory1 >= 0)
        Invariant(memory2 >= 0)
        Invariant(i >= 1)
        Decreases(max(memory1, memory2) - i + 1)
        if memory1 >= memory2:
            memory1 -= i
        else:
            memory2 -= i
        i += 1
    Assert(max(memory1, memory2) < i)
    return [i, memory1, memory2]