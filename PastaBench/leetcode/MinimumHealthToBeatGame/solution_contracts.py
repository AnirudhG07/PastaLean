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

def minimumHealth(damage: List[int], armor: int) -> int:
    Requires(len(damage) > 0)
    Requires(armor >= 0)
    # The minimum health must be at least 1 to survive all hits
    Ensures(Result() >= 1)
    return sum(damage) - min(max(damage), armor) + 1