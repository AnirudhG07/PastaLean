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

def addDigits(num: int) -> int:
    Requires(num >= 0)
    Ensures(
        (num == 0 and Result() == 0)
        or (num > 0 and 1 <= Result() <= 9 and (num - Result()) % 9 == 0)
    )
    return 0 if num == 0 else (num - 1) % 9 + 1