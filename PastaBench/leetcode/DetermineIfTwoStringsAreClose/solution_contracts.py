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

def closeStrings(word1: str, word2: str) -> bool:
    Ensures(
        Result()
        == (
            sorted(Counter(word1).values()) == sorted(Counter(word2).values())
            and set(word1) == set(word2)
        )
    )
    cnt1, cnt2 = Counter(word1), Counter(word2)
    return sorted(cnt1.values()) == sorted(cnt2.values()) and set(cnt1.keys()) == set(cnt2.keys())