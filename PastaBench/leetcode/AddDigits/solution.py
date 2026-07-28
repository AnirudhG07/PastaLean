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

def addDigits(num: int) -> int:
    return 0 if num == 0 else (num - 1) % 9 + 1
