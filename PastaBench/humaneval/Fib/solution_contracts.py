from contracts import *


def fib_spec(k: int) -> int:
    Requires(k >= 0)
    if k == 0:
        return 0
    if k == 1:
        return 1
    return fib_spec(k - 1) + fib_spec(k - 2)


def fib(n: int):
    """Return n-th Fibonacci number.
    >>> fib(10)
    55
    >>> fib(1)
    1
    >>> fib(8)
    21
    """
    Requires(n >= 0)
    Ensures(Result() == fib_spec(n))

    if n == 0: return 0
    Assert(n > 0)
    if n <= 2: return 1
    Assert(n > 2)

    a, b = 1, 1
    # Initially, a = 1 = fib(1) and b = 1 = fib(2)
    for i in range(3, n + 1):
        Invariant(3 <= i)
        Invariant(i <= n + 1)
        Invariant(a == fib_spec(i - 2))
        Invariant(b == fib_spec(i - 1))
        Decreases(n + 1 - i)

        a, b = b, a + b

    # After the loop, i = n + 1. The invariant for b gives:
    # b == fib_spec((n + 1) - 1) == fib_spec(n)
    Assert(b == fib_spec(n))
    return b
