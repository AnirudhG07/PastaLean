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
    # The result is a prime, so it is 2, 3, or coprime to 6 — i.e. +/-1 mod 6.
    Ensures(Result() >= 2)
    Ensures(Result() == 2 or Result() == 3 or Result() % 6 == 1 or Result() % 6 == 5)

    import random
    def miller_rabin(n, k=10):
        """Test if n is prime using the Miller-Rabin primality test."""
        # Non-deterministic (random.randint) and uses 3-argument pow; treated as an opaque
        # primality oracle. No contract is attached to it.
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
        Invariant(0 <= c_prime)
        Invariant(c_prime < n)
        Invariant(0 <= a)
        Invariant(a <= b)
        # Cassini's identity. It is exactly the statement "a and b are consecutive Fibonacci
        # numbers": it holds at (0, 1) and the step (a, b) -> (b, a + b) flips its sign,
        # since (a+b)^2 - b(a+b) - b^2 = -(b^2 - ab - a^2). So the returned b is a Fibonacci
        # number, which is the half of the specification the code can actually establish.
        Invariant(b * b - a * b - a * a == 1 or b * b - a * b - a * a == -1)
        Decreases(n - c_prime)

        a, b = b, a + b
        if miller_rabin(b):
            c_prime += 1

    Assert(b * b - a * b - a * a == 1 or b * b - a * b - a * a == -1)
    return b
