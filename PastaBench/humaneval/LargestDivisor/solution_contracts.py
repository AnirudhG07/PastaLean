from contracts import *


def largest_divisor(n: int) -> int:
    """ For a given number n, find the largest number that divides n evenly, smaller than n
    >>> largest_divisor(15)
    5
    """
    Requires(n >= 2)
    # The result must be a positive, proper divisor of n.
    Ensures(Result() > 0)
    Ensures(Result() < n)
    Ensures(n % Result() == 0)

    # The loop searches for the smallest factor `i` of `n`, starting from 2.
    # If found, `n // i` is the largest factor.
    for i in range(2, n):
        Invariant(2 <= i)
        Invariant(i <= n)
        if n % i == 0:
            # The smallest factor i >= 2 yields the largest divisor n // i.
            Assert(n // i < n)
            Assert(n % (n // i) == 0)
            return n // i

    # If no factor is found in [2, n-1], n is prime, and its largest proper divisor is 1.
    return 1