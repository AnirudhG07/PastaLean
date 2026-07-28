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

def numberOfWeeks(milestones: List[int]) -> int:
    mx, s = (max(milestones), sum(milestones))
    rest = s - mx
    return rest * 2 + 1 if mx > rest + 1 else s
