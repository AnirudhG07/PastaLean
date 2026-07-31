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

def fullBloomFlowers(flowers: List[List[int]], people: List[int]) -> List[int]:
    start, end = (sorted((a for a, _ in flowers)), sorted((b for _, b in flowers)))
    return [bisect_right(start, p) - bisect_left(end, p) for p in people]
