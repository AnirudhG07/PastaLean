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

def sortSentence(s: str) -> str:
    # Preconditions: The input string `s` must be a well-formed "shuffled" sentence.
    # 1. Each word must end in a digit.
    Requires(all(w and w[-1].isdigit() for w in s.split()))
    # 2. The numbers must be unique (implying no gaps or duplicates).
    Requires(len({int(w[-1]) for w in s.split()}) == len(s.split()))
    # 3. The numbers must be within the valid 1-based index range.
    Requires(all(1 <= int(w[-1]) <= len(s.split()) for w in s.split()))

    # Postcondition: The result is the correctly ordered sentence. This is specified
    # declaratively by sorting the (number, word) pairs derived from the input.
    Ensures(
        Result() == ' '.join(
            word for num, word in sorted(
                (int(w[-1]), w[:-1]) for w in s.split()
            )
        )
    )

    ws = s.split()
    ans = [None] * len(ws)
    for w in ws:
        # This assertion is the key to proving memory safety. It follows from the
        # preconditions and states that the array access is always in bounds.
        Assert(0 <= int(w[-1]) - 1 < len(ws))
        ans[int(w[-1]) - 1] = w[:-1]

    # After the loop, `ans` must hold the words in their final, sorted order.
    # This assertion bridges the gap between the loop's effect and the postcondition.
    Assert(
        ans == [
            word for num, word in sorted(
                (int(w[-1]), w[:-1]) for w in ws
            )
        ]
    )
    return ' '.join(ans)