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

def removeAlmostEqualCharacters(word: str) -> int:
    ans = 0
    i, n = (1, len(word))
    while i < n:
        if abs(ord(word[i]) - ord(word[i - 1])) < 2:
            ans += 1
            i += 2
        else:
            i += 1
    return ans
