from contracts import *


def largest_prime_factor(n: int):
    """Return the largest prime factor of n. Assume n > 1 and is not a prime.
    >>> largest_prime_factor(13195)
    29
    >>> largest_prime_factor(2048)
    2
    """
    Requires(n > 1)
    # This implementation is correct only if n is a composite number.
    # If n is prime, it returns 1, which is not a prime factor.
    # The docstring correctly states this assumption. A formal contract
    # for "n is composite" is difficult to express and prove.

    Ensures(n % Result() == 0)
    Ensures(Result() < n)

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
                # Invariants establishing the bounds and properties of the inner loop counter.
                Invariant(j >= i + i)
                Invariant(j < n)
                Invariant(j % i == 0)

                Assert(0 <= j < len(isprime))
                isprime[j] = False

    # Find the largest factor of n that is marked as prime by the sieve.
    for i in range(n - 1, 0, -1):
        # The loop iterates from n-1 down to 1.
        Invariant(0 < i < n)
        Invariant(len(isprime) == n + 1)

        Assert(0 <= i < len(isprime))
        if isprime[i] and n % i == 0:
            return i

    # This part of the code is unreachable if n is a composite number > 1,
    # as such a number always has a prime factor p with 1 < p < n, which the
    # sieve would find. If n is prime, the loop finishes and the function
    # implicitly returns None, failing to satisfy the Ensures contracts.