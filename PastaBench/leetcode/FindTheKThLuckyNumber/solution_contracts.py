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

def kthLuckyNumber(k: int) -> str:
    Requires(k >= 1)
    Ensures(len(Result()) >= 1)

    k_initial = k

    n = 1
    # This loop determines n, the number of digits in the k-th lucky number.
    # After the loop, k is updated to be the 1-based index among numbers of length n.
    while k > 1 << n:
        Invariant(n >= 1)
        Invariant(k >= 1)
        # Invariant: k_initial is the sum of the current k and the count of all lucky
        # numbers with length up to n-1, which is (2^n - 2).
        Invariant(k_initial == k + (1 << n) - 2)
        Decreases(k)
        
        k -= 1 << n
        n += 1

    Assert(n >= 1)
    Assert(1 <= k and k <= (1 << n))

    n_len = n
    ans = []
    
    # This loop constructs the resulting number digit by digit.
    while n:
        Invariant(n >= 1)
        # Invariant: The number of digits generated plus the number of digits
        # remaining is constant and equal to the target length.
        Invariant(len(ans) + n == n_len)
        # Invariant: k is always a valid 1-based index for the remaining n digits.
        Invariant(1 <= k and k <= (1 << n))
        Decreases(n)

        n -= 1
        if k <= 1 << n:
            ans.append('4')
        else:
            ans.append('7')
            k -= 1 << n
            
    Assert(n == 0)
    Assert(len(ans) == n_len)
    
    return ''.join(ans)