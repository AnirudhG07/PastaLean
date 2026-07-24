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

def sumOfThree(num: int) -> List[int]:
    x, mod = divmod(num, 3)
    return [] if mod else [x - 1, x, x + 1]
