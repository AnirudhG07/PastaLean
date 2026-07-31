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

def countCollisions(directions: str) -> int:
    """
    Counts the number of cars that will collide.
    'L': car moving left
    'R': car moving right
    'S': car is stationary

    Collisions happen between:
    - A right-moving car and a left-moving car.
    - A moving car and a stationary car.

    Cars moving left from the start ('L' prefix) and cars moving right at the end
    ('R' suffix) will never collide as they move off the road. All other moving
    cars will eventually be involved in a collision.
    """
    Requires(all(c in ('L', 'R', 'S') for c in directions))
    Ensures(0 <= Result() <= len(directions))
    
    # Remove cars that will not collide: leading 'L's and trailing 'R's.
    s = directions.lstrip('L').rstrip('R')
    
    # In the remaining segment, any car that is not stationary ('S') will collide.
    # The number of such cars is the length of the segment minus the count of 'S'.
    return len(s) - s.count('S')