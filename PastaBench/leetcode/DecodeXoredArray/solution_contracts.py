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


def decode(encoded: List[int], first: int) -> List[int]:
    Ensures(len(Result()) == len(encoded) + 1)
    Ensures(all(Result()[i] ^ Result()[i+1] == encoded[i] for i in range(len(encoded))))
    ans = [first]
    for x in encoded:
        Invariant(len(ans) <= len(encoded) + 1)
        Invariant(all(ans[j] ^ ans[j+1] == encoded[j] for j in range(len(ans)-1)))
        ans.append(ans[-1] ^ x)
    Assert(len(ans) == len(encoded) + 1)
    Assert(all(ans[j] ^ ans[j+1] == encoded[j] for j in range(len(encoded))))
    return ans