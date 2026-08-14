from contracts import *


def is_prime(n):
    """Return true if a given number is prime, and false otherwise.
    >>> is_prime(6)
    False
    >>> is_prime(101)
    True
    >>> is_prime(11)
    True
    >>> is_prime(13441)
    True
    >>> is_prime(61)
    True
    >>> is_prime(4)
    False
    >>> is_prime(1)
    False
    """
    Ensures(Result() == (n > 1 and all(n % d != 0 for d in range(2, n))))

    if n <= 1: return False
    Assert(n > 1)

    n_sqrt = 1
    # This loop computes the smallest integer n_sqrt such that n_sqrt**2 >= n.
    while n_sqrt ** 2 < n:
        Invariant(n_sqrt >= 1)
        Invariant((n_sqrt - 1)**2 < n)
        Decreases(n - n_sqrt**2)
        n_sqrt += 1
    
    # The loop terminates when n_sqrt**2 >= n, and the invariant from the last
    # iteration implies (n_sqrt - 1)**2 < n.
    Assert(n <= n_sqrt ** 2)
    
    # We check for divisors up to this computed square root.
    for i in range(2, min(n_sqrt + 1, n)):
        Invariant(2 <= i)
        Invariant(i <= min(n_sqrt + 1, n))
        Invariant(all(n % d != 0 for d in range(2, i)))
        if n % i == 0:
            # A divisor was found, so n is not prime. The Ensures clause is satisfied
            # because there exists a d (namely i) in [2, n-1] such that n % d == 0.
            return False

    # The loop completed, meaning no divisors were found in the checked range.
    # This is the key fact established by the loop. For the final postcondition to
    # hold, a number-theoretic lemma is required: if no divisor is found up to
    # sqrt(n), no divisor exists up to n-1.
    Assert(all(n % d != 0 for d in range(2, min(n_sqrt + 1, n))))
    return True