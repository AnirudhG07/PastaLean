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


def findGameWinner(n: int) -> bool:
    Requires(n >= 0)
    Ensures(Result() == (n % 6 != 1))
    return n % 6 != 1