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

def maximumBinaryString(binary: str) -> str:
    Requires(all(c == '0' or c == '1' for c in binary))
    Ensures(len(Result()) == len(binary))
    Ensures(
        (binary.find('0') == -1 and Result() == binary) or
        (binary.find('0') != -1 and
         Result().count('0') == 1 and
         Result().find('0') == binary.find('0') + binary.count('0') - 1)
    )

    k = binary.find('0')
    if k == -1:
        Assert(binary.find('0') == -1)
        return binary

    Assert(k != -1)
    Assert(k == binary.find('0'))
    Assert(binary.count('0') == 1 + binary[k + 1:].count('0'))

    k += binary[k + 1:].count('0')

    Assert(0 <= k)
    Assert(k < len(binary))
    Assert(k == binary.find('0') + binary.count('0') - 1)

    return '1' * k + '0' + '1' * (len(binary) - k - 1)