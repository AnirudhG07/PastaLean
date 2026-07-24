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


def getConcatenation(nums: List[int]) -> List[int]:
    Ensures(Result() == nums + nums)
    return nums + nums