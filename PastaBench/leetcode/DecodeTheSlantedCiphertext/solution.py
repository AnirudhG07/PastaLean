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
    ans = []
    cols = len(encodedText) // rows
    for j in range(cols):
        x, y = (0, j)
        while x < rows and y < cols:
            ans.append(encodedText[x * cols + y])
            x, y = (x + 1, y + 1)
    return ''.join(ans).rstrip()
