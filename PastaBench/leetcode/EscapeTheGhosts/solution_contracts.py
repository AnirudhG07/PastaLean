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

def escapeGhosts(ghosts: List[List[int]], target: List[int]) -> bool:
    Requires(len(target) == 2)
    Requires(all(len(g) == 2 for g in ghosts))
    Ensures(
        Result()
        == all(
            abs(target[0] - g[0]) + abs(target[1] - g[1])
            > abs(target[0]) + abs(target[1])
            for g in ghosts
        )
    )

    tx, ty = target
    return all((abs(tx - x) + abs(ty - y) > abs(tx) + abs(ty) for x, y in ghosts))