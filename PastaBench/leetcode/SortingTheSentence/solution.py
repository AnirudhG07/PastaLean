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

def sortSentence(s: str) -> str:
    ws = s.split()
    ans = [None] * len(ws)
    for w in ws:
        ans[int(w[-1]) - 1] = w[:-1]
    return ' '.join(ans)
