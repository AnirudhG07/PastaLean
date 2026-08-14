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

def prefixCount(words: List[str], pref: str) -> int:
    Ensures(0 <= Result())
    Ensures(Result() <= len(words))
    return sum((w.startswith(pref) for w in words))