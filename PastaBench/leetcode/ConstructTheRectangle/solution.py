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

def constructRectangle(area: int) -> List[int]:
    w = int(sqrt(area))
    while area % w != 0:
        w -= 1
    return [area // w, w]
