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

def numOfBurgers(tomatoSlices: int, cheeseSlices: int) -> List[int]:
    k = 4 * cheeseSlices - tomatoSlices
    y = k // 2
    x = cheeseSlices - y
    return [] if k % 2 or y < 0 or x < 0 else [x, y]
