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


def minChanges(n: int, k: int) -> int:
    Requires(n >= 0)
    Requires(k >= 0)
    Ensures(
        (n & k != k and Result() == -1)
        or
        (n & k == k and Result() == (n ^ k).bit_count())
    )
    return -1 if n & k != k else (n ^ k).bit_count()