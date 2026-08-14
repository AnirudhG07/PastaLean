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
    return [chr(i) + str(j) for i in range(ord(s[0]), ord(s[-2]) + 1) for j in range(int(s[1]), int(s[-1]) + 1)]
