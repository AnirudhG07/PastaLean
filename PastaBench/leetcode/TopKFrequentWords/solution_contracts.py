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

def topKFrequent(words: List[str], k: int) -> List[str]:
    Requires(k >= 0)
    Ensures(len(Result()) == min(k, len(set(words))))
    Ensures(len(set(Result())) == len(Result()))
    Ensures(all(word in set(words) for word in Result()))
    cnt = Counter(words)
    return sorted(cnt, key=lambda x: (-cnt[x], x))[:k]