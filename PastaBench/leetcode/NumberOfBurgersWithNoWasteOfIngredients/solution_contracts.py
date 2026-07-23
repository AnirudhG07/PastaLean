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

def numOfBurgers(tomatoSlices: int, cheeseSlices: int) -> List[int]:
    Requires(tomatoSlices >= 0)
    Requires(cheeseSlices >= 0)
    Ensures(
        Result() == []
        or (
            len(Result()) == 2
            and Result()[0] >= 0
            and Result()[1] >= 0
            and Result()[0] + Result()[1] == cheeseSlices
            and 4 * Result()[0] + 2 * Result()[1] == tomatoSlices
        )
    )
    k = 4 * cheeseSlices - tomatoSlices
    y = k // 2
    x = cheeseSlices - y
    if k % 2 or y < 0 or x < 0:
        return []
    # Bridge facts for the non-empty result path
    Assert(k % 2 == 0)
    Assert(2 * y == k)
    Assert(x + y == cheeseSlices)
    Assert(4 * x + 2 * y == tomatoSlices)
    return [x, y]