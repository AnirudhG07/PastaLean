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


def mostWordsFound(sentences: List[str]) -> int:
    Requires(len(sentences) > 0)
    # The result is the maximum word count among all sentences,
    # where each sentence's words = spaces + 1.
    Ensures(all(s.count(' ') + 1 <= Result() for s in sentences))
    Ensures(any(s.count(' ') + 1 == Result() for s in sentences))
    return 1 + max((s.count(' ') for s in sentences))