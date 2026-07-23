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

def getEncryptedString(s: str, k: int) -> str:
    Ensures(all(Result()[i] == s[(i + k) % len(s)] for i in range(len(s))))
    cs = list(s)
    for i in range(len(s)):
        Invariant(0 <= i)
        Invariant(i < len(s))
        Invariant(all(cs[j] == s[(j + k) % len(s)] for j in range(i)))
        Decreases(len(s) - i)
        cs[i] = s[(i + k) % len(s)]
    Assert(all(cs[j] == s[(j + k) % len(s)] for j in range(len(s))))
    return ''.join(cs)