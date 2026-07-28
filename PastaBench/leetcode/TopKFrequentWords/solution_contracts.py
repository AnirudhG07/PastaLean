from contracts import *
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

def topKFrequent(words: List[str], k: int) -> List[str]:
    Requires(k >= 0)
    cnt = Counter(words)
    return sorted(cnt, key=lambda x: (-cnt[x], x))[:k]