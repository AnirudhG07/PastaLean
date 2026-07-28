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

def largestAltitude(gain: List[int]) -> int:
    # The result is exactly the maximum prefix sum starting from altitude 0.
    Ensures(Result() == max(accumulate(gain, initial=0)))
    return max(accumulate(gain, initial=0))