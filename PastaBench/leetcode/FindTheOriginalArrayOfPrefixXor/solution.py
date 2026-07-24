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

def findArray(pref: List[int]) -> List[int]:
    return [a ^ b for a, b in pairwise([0] + pref)]
