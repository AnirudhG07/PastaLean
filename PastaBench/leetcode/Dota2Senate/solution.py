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

def predictPartyVictory(senate: str) -> str:
    qr = deque()
    qd = deque()
    for i, c in enumerate(senate):
        if c == 'R':
            qr.append(i)
        else:
            qd.append(i)
    n = len(senate)
    while qr and qd:
        if qr[0] < qd[0]:
            qr.append(qr[0] + n)
        else:
            qd.append(qd[0] + n)
        qr.popleft()
        qd.popleft()
    return 'Radiant' if qr else 'Dire'
