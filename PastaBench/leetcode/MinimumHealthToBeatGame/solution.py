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
    return sum(damage) - min(max(damage), armor) + 1
