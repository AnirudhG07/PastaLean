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

def escapeGhosts(ghosts: List[List[int]], target: List[int]) -> bool:
    tx, ty = target
    return all((abs(tx - x) + abs(ty - y) > abs(tx) + abs(ty) for x, y in ghosts))
