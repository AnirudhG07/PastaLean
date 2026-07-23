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

def minPartitions(n: str) -> int:
    Requires(len(n) > 0)
    # The result is the maximum digit in the decimal string n
    Ensures(Result() == int(max(n)))
    return int(max(n))