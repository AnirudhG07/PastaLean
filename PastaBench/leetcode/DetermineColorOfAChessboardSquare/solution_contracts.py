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


def squareIsWhite(coordinates: str) -> bool:
    Requires(len(coordinates) == 2)
    Requires(coordinates[0] in 'abcdefgh')
    Requires(coordinates[1] in '12345678')
    return (ord(coordinates[0]) + ord(coordinates[1])) % 2 == 1