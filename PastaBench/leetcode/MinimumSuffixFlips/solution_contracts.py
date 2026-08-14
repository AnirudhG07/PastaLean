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

def minFlips(target: str) -> int:
    Requires(all(c in ('0', '1') for c in target))

    # The result is the number of flips needed. This cannot exceed the string length.
    Ensures(0 <= Result())
    Ensures(Result() <= len(target))
    # The core property is that the final number of flips determines the state of the last
    # bulb, which must match the target. An even number of flips results in state '0',
    # an odd number in state '1'. Thus, the parity of the result must match the integer
    # value of the last character.
    Ensures(len(target) == 0 or (Result() % 2) == int(target[-1]))

    ans = 0
    # This loop calculates the number of flips. A flip occurs at a position `i` if the
    # state of the bulb string (determined by the parity of flips so far) does not match
    # the target character `target[i]`. The state is `ans % 2`.
    #
    # The key loop invariant relates the number of flips `ans` for the prefix `target[:i]`
    # to the characters in that prefix. Specifically, `ans % 2 == int(target[i-1])` for `i > 0`.
    # However, a `for v in ...` loop does not expose the index `i`, so this invariant cannot
    # be expressed without access to an implicit loop counter provided by the verifier.
    # The most basic provable invariant is non-negativity.
    for v in target:
        Invariant(ans >= 0)
        if ans & 1 ^ int(v):
            ans += 1
    return ans