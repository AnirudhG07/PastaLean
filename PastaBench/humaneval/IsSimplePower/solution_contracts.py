from contracts import *


def is_simple_power(x, n):
    """Your task is to write a function that returns true if a number x is a simple
    power of n and false in other cases.
    x is a simple power of n if n**int=x
    For example:
    is_simple_power(1, 4) => true
    is_simple_power(2, 2) => true
    is_simple_power(8, 2) => true
    is_simple_power(3, 2) => false
    is_simple_power(3, 1) => false
    is_simple_power(5, 3) => false
    """
    # For |n| >= 2 the powers grow at least as fast as 2**k, so bounding |x| bounds the
    # exponent that has to be searched: k <= 62 whenever n ** k == x.
    Requires(-(2 ** 62) <= x <= 2 ** 62)
    # THE POINT: the answer is exactly "x is n raised to some non-negative integer power".
    Ensures(Result() == any(n ** k == x for k in range(0, 63)))

    if x == 1: return True
    if n == 0: return x == 0
    if n == 1: return x == 1
    if n == -1: return abs(x) == 1

    Assert(abs(n) >= 2)

    p = n
    while abs(p) <= abs(x):
        # THE loop invariant: p is always an exact power of n, so the `p == x` test below
        # can only ever answer True for an x that genuinely is a power of n.
        Invariant(any(p == n ** k for k in range(0, 63)))
        Invariant(abs(n) >= 2)
        Decreases(abs(x) + 1 - abs(p))
        if p == x: return True
        p = p * n
    return False
