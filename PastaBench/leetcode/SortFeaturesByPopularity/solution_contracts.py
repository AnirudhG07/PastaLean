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

def sortFeatures(features: List[str], responses: List[str]) -> List[str]:
    Ensures(Result() == sorted(features, key=lambda w: -cnt[w]))
    cnt = Counter()
    for s in responses:
        for w in set(s.split()):
            cnt[w] += 1
    return sorted(features, key=lambda w: -cnt[w])