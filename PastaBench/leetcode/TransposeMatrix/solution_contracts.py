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

def transpose(matrix: List[List[int]]) -> List[List[int]]:
    """
    Computes the transpose of a matrix.
    The matrix is represented as a list of lists.
    """
    Requires(not matrix or all(len(row) == len(matrix[0]) for row in matrix))

    Ensures(len(Result()) == (len(matrix[0]) if matrix else 0))
    Ensures(all(len(row) == len(matrix) for row in Result()))
    Ensures(
        all(
            all(Result()[j][i] == matrix[i][j] for i in range(len(matrix)))
            for j in range(len(matrix[0]) if matrix else 0)
        )
    )
    return list(zip(*matrix))