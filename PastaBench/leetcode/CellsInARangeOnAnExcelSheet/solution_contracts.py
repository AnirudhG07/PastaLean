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

def cellsInRange(s: str) -> List[str]:
    Requires(len(s) == 5)
    Requires(s[2] == ':')
    Requires(ord('A') <= ord(s[0]) and ord(s[0]) <= ord('Z'))
    Requires(ord('A') <= ord(s[-2]) and ord(s[-2]) <= ord('Z'))
    Requires(ord('1') <= ord(s[1]) and ord(s[1]) <= ord('9'))
    Requires(ord('1') <= ord(s[-1]) and ord(s[-1]) <= ord('9'))
    Requires(ord(s[0]) <= ord(s[-2]))
    Requires(int(s[1]) <= int(s[-1]))

    Ensures(len(Result()) == (ord(s[-2]) - ord(s[0]) + 1) * (int(s[-1]) - int(s[1]) + 1))

    return [chr(i) + str(j) for i in range(ord(s[0]), ord(s[-2]) + 1) for j in range(int(s[1]), int(s[-1]) + 1)]