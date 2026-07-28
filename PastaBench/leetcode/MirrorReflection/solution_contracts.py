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


def mirrorReflection(p: int, q: int) -> int:
    Requires(p > 0)
    Requires(q > 0)
    # The result follows the rule:
    # if (p/g)%2==1 and (q/g)%2==1 then 1,
    # elif (p/g)%2==1 then 0,
    # else 2.
    Ensures(
        (p == 1 and q == 1 and Result() == 1)
        or (p == 1 and q != 1 and Result() == 0)
        or (p != 1 and Result() == 2)
    )
    g = gcd(p, q)
    Assert(g > 0)
    p = p // g % 2
    Assert(p == 0 or p == 1)
    q = q // g % 2
    Assert(q == 0 or q == 1)
    if p == 1 and q == 1:
        return 1
    Assert(not (p == 1 and q == 1))
    return 0 if p == 1 else 2