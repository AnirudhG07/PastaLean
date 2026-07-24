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


def countOdds(low: int, high: int) -> int:
    Requires(low <= high)
    # The result is the number of odd integers in the inclusive range [low, high].
    Ensures(Result() == sum(1 for i in range(low, high + 1) if i % 2 != 0))
    return (high + 1 >> 1) - (low >> 1)