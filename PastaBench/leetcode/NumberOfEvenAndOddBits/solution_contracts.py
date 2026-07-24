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

def evenOddBit(n: int) -> List[int]:
    Requires(n >= 0)
    # capture the original value for postconditions
    old_n = n
    Ensures(Result()[0] == sum((old_n >> k) & 1 for k in range(old_n.bit_length()) if k % 2 == 0))
    Ensures(Result()[1] == sum((old_n >> k) & 1 for k in range(old_n.bit_length()) if k % 2 == 1))
    ans = [0, 0]
    i = 0
    while n:
        Invariant(n >= 0)
        Invariant(0 <= i)
        Invariant(i <= 1)
        # t = number of bits processed so far = old_n.bit_length() - n.bit_length()
        Invariant(i == (old_n.bit_length() - n.bit_length()) % 2)
        Invariant(ans[0] ==
                  sum((old_n >> k) & 1
                      for k in range(old_n.bit_length() - n.bit_length())
                      if k % 2 == 0))
        Invariant(ans[1] ==
                  sum((old_n >> k) & 1
                      for k in range(old_n.bit_length() - n.bit_length())
                      if k % 2 == 1))
        Decreases(n)
        ans[i] += n & 1
        i ^= 1
        n >>= 1
    return ans