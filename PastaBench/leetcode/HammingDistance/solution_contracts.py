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

def hammingDistance(x: int, y: int) -> int:
    Requires(x >= 0)
    Requires(y >= 0)
    Ensures(Result() >= 0)
    return (x ^ y).bit_count()