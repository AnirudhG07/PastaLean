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

def lengthOfLastWord(s: str) -> int:
    i = len(s) - 1
    while i >= 0 and s[i] == ' ':
        i -= 1
    j = i
    while j >= 0 and s[j] != ' ':
        j -= 1
    return i - j
