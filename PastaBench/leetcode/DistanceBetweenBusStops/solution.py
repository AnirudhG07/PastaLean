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

def distanceBetweenBusStops(distance: List[int], start: int, destination: int) -> int:
    s = sum(distance)
    t, n = (0, len(distance))
    while start != destination:
        t += distance[start]
        start = (start + 1) % n
    return min(t, s - t)
