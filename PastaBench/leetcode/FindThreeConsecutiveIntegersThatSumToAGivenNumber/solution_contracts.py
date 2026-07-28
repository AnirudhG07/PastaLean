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

def sumOfThree(num: int) -> List[int]:
    Ensures(
        (num % 3 != 0 and Result() == [])
        or
        (num % 3 == 0
         and len(Result()) == 3
         and Result()[1] - Result()[0] == 1
         and Result()[2] - Result()[1] == 1
         and sum(Result()) == num
        )
    )
    x, mod = divmod(num, 3)
    if mod:
        return []
    Assert(num % 3 == 0)
    res = [x - 1, x, x + 1]
    Assert(len(res) == 3)
    Assert(res[1] - res[0] == 1)
    Assert(res[2] - res[1] == 1)
    Assert(res[0] + res[1] + res[2] == num)
    return res