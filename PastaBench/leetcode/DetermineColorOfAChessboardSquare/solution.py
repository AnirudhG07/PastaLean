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
    return (ord(coordinates[0]) + ord(coordinates[1])) % 2 == 1
