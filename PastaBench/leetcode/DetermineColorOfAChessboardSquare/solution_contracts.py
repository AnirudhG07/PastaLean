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

def squareIsWhite(coordinates: str) -> bool:
    Requires(len(coordinates) == 2)
    Requires('a' <= coordinates[0] and coordinates[0] <= 'h')
    Requires('1' <= coordinates[1] and coordinates[1] <= '8')
    # The color of a square depends on the parity of the sum of its coordinates.
    # A square is white if the sum of its 0-indexed coordinates (file and rank) is odd.
    # This postcondition connects the implementation's bit-trick to this domain rule.
    Ensures(Result() == (((ord(coordinates[0]) - ord('a')) + (ord(coordinates[1]) - ord('1'))) % 2 == 1))
    return (ord(coordinates[0]) + ord(coordinates[1])) % 2 == 1