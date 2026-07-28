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

def distributeCandies(candies: int, num_people: int) -> List[int]:
    Requires(candies >= 0)
    Requires(num_people > 0)
    orig_candies = candies
    Ensures(sum(Result()) == orig_candies)    # the returned distribution sums to all candies
    ans = [0] * num_people
    i = 0
    while candies:
        Invariant(candies >= 0)
        Invariant(candies <= orig_candies)
        Invariant(sum(ans) + candies == orig_candies)
        Invariant(i >= 0)
        Invariant(i % num_people >= 0)
        Invariant(i % num_people < num_people)
        Decreases(candies)
        ans[i % num_people] += min(candies, i + 1)
        candies -= min(candies, i + 1)
        i += 1
    Assert(candies == 0)
    Assert(sum(ans) == orig_candies)
    return ans