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

def finalValueAfterOperations(operations: List[str]) -> int:
    return sum((1 if s[1] == '+' else -1 for s in operations))
