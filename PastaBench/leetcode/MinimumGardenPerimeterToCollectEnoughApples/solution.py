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

def minimumPerimeter(neededApples: int) -> int:
    x = 1
    while 2 * x * (x + 1) * (2 * x + 1) < neededApples:
        x += 1
    return x * 8
