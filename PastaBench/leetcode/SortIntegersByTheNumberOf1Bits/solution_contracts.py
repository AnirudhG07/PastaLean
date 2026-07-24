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

from contracts import *

def sortByBits(arr: List[int]) -> List[int]:
    Ensures(len(Result()) == len(arr))
    Ensures(all(Result().count(x) == arr.count(x) for x in arr))
    Ensures(all(
        (Result()[i].bit_count(), Result()[i]) <=
        (Result()[i+1].bit_count(), Result()[i+1])
        for i in range(len(Result()) - 1)
    ))
    return sorted(arr, key=lambda x: (x.bit_count(), x))