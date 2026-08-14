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

def frequencySort(s: str) -> str:
    """
    Sorts a string based on the frequency of its characters.
    Characters with higher frequency appear before characters with lower frequency.
    Characters with the same frequency are grouped together; their relative order is not specified.
    """
    # The output is a permutation of the input string.
    Ensures(Counter(Result()) == Counter(s))
    # For any two adjacent, different characters in the result, the frequency of the
    # character on the left is greater than or equal to the frequency of the character on the right.
    # This captures the essence of "sorted by frequency".
    Ensures(all(
        Counter(s)[Result()[i]] >= Counter(s)[Result()[i + 1]]
        for i in range(len(Result()) - 1)
        if Result()[i] != Result()[i + 1]
    ))
    cnt = Counter(s)
    return ''.join((c * v for c, v in sorted(cnt.items(), key=lambda x: -x[1])))