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

def decodeCiphertext(encodedText: str, rows: int) -> str:
    Requires(rows > 0)
    Requires(len(encodedText) % rows == 0)
    Ensures(len(Result()) <= len(encodedText))
    ans = []
    cols = len(encodedText) // rows
    Assert(cols * rows == len(encodedText))
    for j in range(cols):
        Invariant(0 <= j)
        Invariant(j <= cols)
        x, y = (0, j)
        while x < rows and y < cols:
            Invariant(0 <= x)
            Invariant(x <= rows)
            Invariant(j <= y)
            Invariant(y <= cols)
            Invariant(y == x + j)
            Assert(0 <= x * cols + y < len(encodedText))
            ans.append(encodedText[x * cols + y])
            x, y = (x + 1, y + 1)
    return ''.join(ans).rstrip()