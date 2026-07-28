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

def maxBottlesDrunk(numBottles: int, numExchange: int) -> int:
    Requires(numBottles >= 0)
    Requires(numExchange > 1)
    initialBottles = numBottles
    initialExchange = numExchange
    Ensures(Result() - initialBottles == numExchange - initialExchange)
    Ensures(numBottles < numExchange)
    ans = numBottles
    while numBottles >= numExchange:
        Invariant(numBottles >= 0)
        Invariant(numExchange >= initialExchange)
        Invariant(ans - initialBottles == numExchange - initialExchange)
        Decreases(numBottles)
        numBottles -= numExchange
        numExchange += 1
        ans += 1
        numBottles += 1
    Assert(ans - initialBottles == numExchange - initialExchange)
    Assert(numBottles < numExchange)
    return ans