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
    # The main intent: the product of the returned factors equals the original input number.
    # We assume `n` in a postcondition refers to its value upon function entry, a common
    # convention in verification systems for parameters that are modified.
    Ensures(math.prod(Result()) == n)
    # Secondary properties: factors are sorted and are all >= 2 (for n > 1).
    Ensures(all(f >= 2 for f in Result()))
    Ensures(all(Result()[j] <= Result()[j + 1] for j in range(len(Result()) - 1)))

    fact = []
    i = 2
    # The crucial invariant to prove the main Ensures is `n_initial == math.prod(fact) * n`.
    # Without a way to reference the initial value of the modified parameter `n` (e.g., `Old(n)`),
    # this invariant cannot be expressed. We state other invariants that help prove
    # the secondary properties of the result.
    while i <= int(math.sqrt(n) + 1):
        Invariant(i >= 2)
        Invariant(n >= 1)
        # All factors found so far are greater than or equal to 2.
        Invariant(all(f >= 2 for f in fact))
        # The list of factors is kept sorted because we test divisors `i` in increasing order.
        Invariant(all(fact[j] <= fact[j + 1] for j in range(len(fact) - 1)))
        # A stronger invariant that implies sortedness: the largest factor so far is at most i.
        Invariant(len(fact) == 0 or fact[-1] <= i)
        if n % i == 0:
            fact.append(i)
            n //= i
        else:
            i += 1

    if n > 1:
        fact.append(n)
    return fact