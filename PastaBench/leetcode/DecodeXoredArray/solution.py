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

def decode(encoded: List[int], first: int) -> List[int]:
    ans = [first]
    for x in encoded:
        ans.append(ans[-1] ^ x)
    return ans
