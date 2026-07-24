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

def findLUSlength(a: str, b: str) -> int:
    Ensures((a == b and Result() == -1) or (a != b and Result() == max(len(a), len(b))))
    return -1 if a == b else max(len(a), len(b))