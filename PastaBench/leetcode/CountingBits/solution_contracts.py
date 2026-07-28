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

def countBits(n: int) -> List[int]:
    Requires(n >= 0)
    Ensures(len(Result()) == n + 1)
    Ensures(all(Result()[i] == i.bit_count() for i in range(n + 1)))
    return [i.bit_count() for i in range(n + 1)]