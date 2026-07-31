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

def isThree(n: int) -> bool:
    return sum((n % i == 0 for i in range(2, n))) == 1
