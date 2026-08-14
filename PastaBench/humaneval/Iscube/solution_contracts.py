from typing import *
from contracts import *


def iscube(a: int):
    '''
    Write a function that takes an integer a and returns True
    if this ingeger is a cube of some integer number.
    Note: you may assume the input is always valid.
    Examples:
    iscube(1) ==> True
    iscube(2) ==> False
    iscube(-1) ==> True
    iscube(64) ==> True
    iscube(0) ==> True
    iscube(180) ==> False
    '''
    # THE POINT (1): the answer is exactly "the integer root the code computes cubes back to |a|".
    # `abs` is idempotent, so `abs(a)` denotes the same value before and after `a = abs(a)` — this
    # postcondition therefore reads the same against the entry value and the mutated one, which is
    # what lets it be stated without an `Old`-style operator (there is none in the vocabulary).
    Ensures(Result() == (int(round(abs(a) ** (1. / 3))) ** 3 == abs(a)))
    # THE POINT (2): soundness. A `True` answer is not merely "the float root happened to work" —
    # it witnesses a genuine integer k with k**3 == |a|, i.e. |a| really is a perfect cube. (And
    # testing |a| loses nothing: k**3 == -m exactly when (-k)**3 == m.)
    Ensures(not Result() or any(k * k * k == abs(a) for k in range(abs(a) + 1)))

    a = abs(a)
    Assert(a >= 0)
    r = int(round(a ** (1. / 3)))
    # The rounded cube root of a non-negative number is itself non-negative, and when it is the
    # witness above it is bounded by `a`, which is what puts it inside `range(a + 1)`.
    Assert(r >= 0)
    return r ** 3 == a
