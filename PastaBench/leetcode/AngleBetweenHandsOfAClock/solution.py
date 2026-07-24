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

def angleClock(hour: int, minutes: int) -> float:
    h = 30 * hour + 0.5 * minutes
    m = 6 * minutes
    diff = abs(h - m)
    return min(diff, 360 - diff)
