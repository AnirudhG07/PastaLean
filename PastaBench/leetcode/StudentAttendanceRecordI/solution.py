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

def checkRecord(s: str) -> bool:
    return s.count('A') < 2 and 'LLL' not in s
