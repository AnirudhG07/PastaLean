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

def commonChars(words: List[str]) -> List[str]:
    cnt = Counter(words[0])
    for w in words:
        t = Counter(w)
        for c in cnt:
            cnt[c] = min(cnt[c], t[c])
    return list(cnt.elements())
