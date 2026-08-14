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

def maskPII(s: str) -> str:
    if s[0].isalpha():
        s = s.lower()
        return s[0] + '*****' + s[s.find('@') - 1:]
    s = ''.join((c for c in s if c.isdigit()))
    cnt = len(s) - 10
    suf = '***-***-' + s[-4:]
    return suf if cnt == 0 else f"+{'*' * cnt}-{suf}"
