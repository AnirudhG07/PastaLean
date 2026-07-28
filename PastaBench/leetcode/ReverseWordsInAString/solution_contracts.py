from contracts import *

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

def reverseWords(s: str) -> str:
    Ensures(Result().split() == list(reversed(s.split())))
    return ' '.join(reversed(s.split()))