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

def bulbSwitch(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() * Result() <= n < (Result() + 1) * (Result() + 1))
    return int(sqrt(n))