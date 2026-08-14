from typing import List
from contracts import *
import math


def factorize(n: int) -> List[int]:
    """ Return list of prime factors of given integer in the order from smallest to largest.
    Each of the factors should be listed number of times corresponding to how many times it appeares in factorization.
    Input number should be equal to the product of all factors
    >>> factorize(8)
    [2, 2, 2]
    >>> factorize(25)
    [5, 5]
    >>> factorize(70)
    [2, 5, 7]
    """
    Requires(n >= 1)
    # The point, in three parts: the factors multiply back to the input, they come out in
    # non-decreasing order, and each one is prime.
    Ensures(math.prod(Result()) == n)
    Ensures(all(Result()[j] <= Result()[j + 1] for j in range(len(Result()) - 1)))
    Ensures(all(
        all(f % d != 0 for d in range(2, int(math.sqrt(f)) + 2) if d < f)
        for f in Result()
    ))
    Ensures(all(f >= 2 for f in Result()))

    fact = []
    # The remainder is peeled into `m`; the parameter `n` stays intact so the postcondition
    # above refers to the input rather than to whatever is left at the end.
    m = n
    i = 2
    while i <= int(math.sqrt(m) + 1):
        Invariant(i >= 2)
        Invariant(m >= 1)
        # The invariant that carries the product postcondition: what has been peeled off times
        # what is left is always the input.
        Invariant(math.prod(fact) * m == n)
        Invariant(all(f >= 2 for f in fact))
        # Divisors are tried in increasing order, so nothing already recorded exceeds `i`;
        # that is what keeps `fact` sorted.
        Invariant(len(fact) == 0 or fact[-1] <= i)
        Invariant(all(fact[j] <= fact[j + 1] for j in range(len(fact) - 1)))
        if m % i == 0:
            fact.append(i)
            m //= i
        else:
            i += 1

    # Whatever survives trial division past its own square root is itself prime.
    if m > 1:
        fact.append(m)

    Assert(math.prod(fact) == n)
    return fact
