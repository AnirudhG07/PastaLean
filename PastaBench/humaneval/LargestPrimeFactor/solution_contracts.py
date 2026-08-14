from contracts import *


def largest_prime_factor(n: int):
    """Return the largest prime factor of n. Assume n > 1 and is not a prime.
    >>> largest_prime_factor(13195)
    29
    >>> largest_prime_factor(2048)
    2
    """
    Requires(n > 1)
    # The docstring's "and is not a prime" assumption, stated formally: n has a proper divisor.
    # Without it the final loop falls through and the function returns nothing.
    Requires(any(n % d == 0 for d in range(2, n)))

    # THE POINT: the result is a prime divisor of n.
    Ensures(Result() > 1)
    Ensures(n % Result() == 0)
    # Primality by trial division (the guard is the implication `Result() > 1 -> ...`).
    Ensures(Result() <= 1 or all(Result() % d != 0 for d in range(2, Result())))

    isprime = [True] * (n + 1)
    Assert(len(isprime) == n + 1)

    # Sieve of Eratosthenes to find all primes up to n.
    for i in range(2, n + 1):
        Invariant(2 <= i <= n + 1)
        Invariant(len(isprime) == n + 1)

        Assert(0 <= i < len(isprime))
        if isprime[i]:
            for j in range(i + i, n, i):
                Invariant(i >= 2)
                Invariant(len(isprime) == n + 1)
                Invariant(j >= i + i)
                Invariant(j < n)
                Invariant(j % i == 0)

                Assert(0 <= j < len(isprime))
                isprime[j] = False

    # Scan downwards, so the first sieve-prime divisor found is the largest one.
    for i in range(n - 1, 0, -1):
        Invariant(0 < i < n)
        Invariant(len(isprime) == n + 1)
        Decreases(i)

        Assert(0 <= i < len(isprime))
        if isprime[i] and n % i == 0:
            return i

    # Unreachable under the precondition: a composite n > 1 always has a prime factor p < n.
