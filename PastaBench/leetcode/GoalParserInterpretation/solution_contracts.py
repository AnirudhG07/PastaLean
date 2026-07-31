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

def interpret(command: str) -> str:
    """
    Interprets a command string according to specific replacement rules:
    - "()" is replaced by "o"
    - "(al)" is replaced by "al"
    """
    Ensures(len(Result()) <= len(command))
    Ensures(Result().count('G') == command.count('G'))
    Ensures("()" not in Result())
    Ensures("(al)" not in Result())
    return command.replace('()', 'o').replace('(al)', 'al')