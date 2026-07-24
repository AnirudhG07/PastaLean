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

def arrayStringsAreEqual(word1: List[str], word2: List[str]) -> bool:
    Ensures(Result() == (''.join(word1) == ''.join(word2)))
    return ''.join(word1) == ''.join(word2)