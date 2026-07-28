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

def sum(num1: int, num2: int) -> int:
    Ensures(Result() == num1 + num2)
    return num1 + num2