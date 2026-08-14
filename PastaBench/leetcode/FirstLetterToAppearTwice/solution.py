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

def repeatedCharacter(s: str) -> str:
    cnt = Counter()
    for c in s:
        cnt[c] += 1
        if cnt[c] == 2:
            return c
