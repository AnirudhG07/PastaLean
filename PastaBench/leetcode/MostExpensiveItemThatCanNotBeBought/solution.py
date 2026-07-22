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

def mostExpensiveItem(primeOne: int, primeTwo: int) -> int:
    return primeOne * primeTwo - primeOne - primeTwo
