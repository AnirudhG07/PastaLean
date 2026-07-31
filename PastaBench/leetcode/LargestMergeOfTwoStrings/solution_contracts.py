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
from contracts import *

def largestMerge(word1: str, word2: str) -> str:
    Ensures(len(Result()) == len(word1) + len(word2))
    i = j = 0
    ans = []
    while i < len(word1) and j < len(word2):
        Invariant(0 <= i <= len(word1))
        Invariant(0 <= j <= len(word2))
        Invariant(len(ans) == i + j)
        Decreases((len(word1) - i) + (len(word2) - j))
        if word1[i:] > word2[j:]:
            ans.append(word1[i])
            i += 1
        else:
            ans.append(word2[j])
            j += 1
    ans.append(word1[i:])
    ans.append(word2[j:])
    return ''.join(ans)