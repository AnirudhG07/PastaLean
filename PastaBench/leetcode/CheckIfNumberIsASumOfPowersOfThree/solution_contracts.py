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

def checkPowersOfThree(n: int) -> bool:
    Requires(n >= 0)
    while n:
        if n % 3 > 1:
            return False
        n //= 3
    return True