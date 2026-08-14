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

def encode(num: int) -> str:
    Requires(num >= 0)
    Ensures(num + 1 == int('1' + Result(), 2))
    return bin(num + 1)[3:]