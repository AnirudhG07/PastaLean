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

def largestMerge(word1: str, word2: str) -> str:
    i = j = 0
    ans = []
    while i < len(word1) and j < len(word2):
        if word1[i:] > word2[j:]:
            ans.append(word1[i])
            i += 1
        else:
            ans.append(word2[j])
            j += 1
    ans.append(word1[i:])
    ans.append(word2[j:])
    return ''.join(ans)
