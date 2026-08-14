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


def customSortString(order: str, s: str) -> str:
    # The 'order' string defines a custom character priority. It's assumed to have unique characters.
    Requires(len(set(order)) == len(order))

    # Postcondition 1: The output must be a permutation of the input string 's'.
    # This means they have the same characters with the same frequencies.
    Ensures(collections.Counter(Result()) == collections.Counter(s))

    # Postcondition 2: The output string must be sorted according to the key function.
    # The key for a character is its index in 'order', or a default value (0) if not present.
    # This ensures that for any two adjacent characters in the result, the key of the
    # first is less than or equal to the key of the second.
    Ensures(
        all(
            {c: k for k, c in enumerate(order)}.get(Result()[i], 0)
            <= {c: k for k, c in enumerate(order)}.get(Result()[i + 1], 0)
            for i in range(len(Result()) - 1)
        )
    )

    d = {c: i for i, c in enumerate(order)}
    return ''.join(sorted(s, key=lambda x: d.get(x, 0)))