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

def wordsTyping(sentence: List[str], rows: int, cols: int) -> int:
    Requires(rows >= 0)
    Requires(cols >= 0)
    Requires(len(sentence) > 0)
    Requires(all(len(w) <= cols for w in sentence))
    s = ' '.join(sentence) + ' '
    m = len(s)
    cur = 0
    for _ in range(rows):
        cur += cols
        if s[cur % m] == ' ':
            cur += 1
        while cur and s[(cur - 1) % m] != ' ':
            cur -= 1
    return cur // m