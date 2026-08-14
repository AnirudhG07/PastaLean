import random
import functools
import collections
import string
import math
import datetime
from contracts import *
from typing import *
from functools import *
from collections import *
from itertools import *
from heapq import *
from bisect import *
from string import *
from operator import *
from math import *

def countPrefixes(words: List[str], s: str) -> int:
    Ensures(0 <= Result())
    Ensures(Result() <= len(words))
    return sum((s.startswith(w) for w in words))