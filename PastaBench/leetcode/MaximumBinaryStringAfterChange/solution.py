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

def maximumBinaryString(binary: str) -> str:
    k = binary.find('0')
    if k == -1:
        return binary
    k += binary[k + 1:].count('0')
    return '1' * k + '0' + '1' * (len(binary) - k - 1)
