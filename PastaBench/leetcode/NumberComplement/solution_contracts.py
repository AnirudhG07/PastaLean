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


def findComplement(num: int) -> int:
    Requires(num >= 0)
    # The result flips all bits of num within its bit-length: num + result == (2^k - 1)
    Ensures(num + Result() == (1 << num.bit_length()) - 1)
    return num ^ (1 << num.bit_length()) - 1