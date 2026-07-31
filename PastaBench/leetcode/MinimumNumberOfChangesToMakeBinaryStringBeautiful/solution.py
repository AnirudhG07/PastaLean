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

def minChanges(s: str) -> int:
    return sum((s[i] != s[i - 1] for i in range(1, len(s), 2)))
