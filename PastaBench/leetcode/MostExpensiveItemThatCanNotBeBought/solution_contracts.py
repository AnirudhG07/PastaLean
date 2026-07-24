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

def mostExpensiveItem(primeOne: int, primeTwo: int) -> int:
    Requires(primeOne > 0)
    Requires(primeTwo > 0)
    Requires(gcd(primeOne, primeTwo) == 1)
    Ensures(Result() == primeOne * primeTwo - primeOne - primeTwo)
    return primeOne * primeTwo - primeOne - primeTwo