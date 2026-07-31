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

def isThree(n: int) -> bool:
    """
    Checks if an integer has exactly three positive divisors.
    This is true if and only if the number is the square of a prime number.
    """
    Requires(n >= 1)
    # If the function returns true, n must be at least 4 (the square of the smallest prime, 2).
    Ensures(not Result() or n >= 4)
    # A number has three divisors iff it is a perfect square of a prime.
    # This contract captures the "perfect square" part of that property.
    Ensures(not Result() or (isqrt(n) * isqrt(n) == n))

    # The implementation counts the number of divisors in the range [2, n-1].
    # For a number n = p*p where p is prime, the only divisor in this range is p.
    # For any other number, the count of divisors in this range is not 1.
    return sum((n % i == 0 for i in range(2, n))) == 1