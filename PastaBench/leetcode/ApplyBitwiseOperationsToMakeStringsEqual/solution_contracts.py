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

def makeStringsEqual(s: str, target: str) -> bool:
    Ensures(Result() == (('1' in s) == ('1' in target)))
    return ('1' in s) == ('1' in target)