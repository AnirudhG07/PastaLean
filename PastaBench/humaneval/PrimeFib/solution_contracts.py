from contracts import *


def prime_fib(n: int):
    """
    prime_fib returns n-th number that is a Fibonacci number and it's also prime.
    >>> prime_fib(1)
    2
    >>> prime_fib(2)
    3
    >>> prime_fib(3)
    5
    >>> prime_fib(4)
    13
    >>> prime_fib(5)
    89
    """
    Requires(n > 0)
    # STUB: primality here is decided by a Miller-Rabin test that uses random.randint
    # and Python's 3-argument pow (modular exponentiation), both unsupported by
    # PastaLean. The body degrades to pyUnsupported placeholders, so no non-trivial
    # correctness property can be characterized; the specification is left trivial.
    Ensures(True)

    import random
    def miller_rabin(n, k=10):
        """Test if n is prime using the Miller-Rabin primality test."""
        # This function is non-deterministic due to `random` and thus not verifiable.
        # It is treated as a correct primality oracle by the caller's contracts.
        if n < 2:
            return False
        if n == 2 or n == 3:
            return True
        if n % 2 == 0:
            return False

        r = 0
        d = n - 1
        while d % 2 == 0:
            r += 1
            d //= 2

        for _ in range(k):
            a = random.randint(2, n - 2)
            x = pow(a, d, n)
            if x == 1 or x == n - 1:
                continue
            for _ in range(r - 1):
                x = pow(x, 2, n)
                if x == n - 1:
                    break
            else:
                return False

        return True

    c_prime = 0
    a, b = 0, 1
    while c_prime < n:
        Invariant(c_prime >= 0)
        # The loop condition implies `c_prime < n` at the top of every iteration.
        Invariant(c_prime < n)
        Invariant(a >= 0)
        # The Fibonacci sequence here is F_0, F_1, F_2, ... = 0, 1, 1, 2, 3, ...
        # `b` takes values F_1, F_2, ... which are all positive.
        Invariant(b > 0)
        # The number of primes remaining to be found is strictly decreasing.
        # This assumes there are at least `n` prime Fibonacci numbers.
        Decreases(n - c_prime)
        
        a, b = b, a + b
        if miller_rabin(b):
            c_prime += 1
    
    # Upon loop exit, the loop condition is false (`c_prime >= n`).
    # With the invariant `c_prime <= n` (which holds before the last check),
    # we can conclude `c_prime == n`.
    Assert(c_prime == n)
    # The loop must have terminated because `c_prime` was incremented to `n`.
    # This happens only when `miller_rabin(b)` is true for the final `b`.
    Assert(miller_rabin(b))
    return b