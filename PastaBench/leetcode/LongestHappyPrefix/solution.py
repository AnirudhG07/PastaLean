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

def longestPrefix(s: str) -> str:
    for i in range(1, len(s)):
        if s[:-i] == s[i:]:
            return s[i:]
    return ''
