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

def numSpecialEquivGroups(words: List[str]) -> int:
    s = {''.join(sorted(word[::2]) + sorted(word[1::2])) for word in words}
    return len(s)
