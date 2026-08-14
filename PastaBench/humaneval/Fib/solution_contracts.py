from contracts import *


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
    # THE POINT: a growth bound. The loop keeps the rolling window (a, b) = (F(i-2), F(i-1)) with
    # both entries at least 1, so each step adds at least 1 to the larger one and the sequence
    # outgrows its own index: F(n) >= n - 1 for every n, and F(n) >= 1 once n >= 1. Neither is
    # readable off the code — both come straight out of the window invariants below.
    Ensures(Result() >= n - 1)
    Ensures(n <= 0 or Result() >= 1)

    if n == 0: return 0
    if n <= 2: return 1
    Assert(n > 2)

    a, b = 1, 1
    for i in range(3, n + 1):
        Invariant(3 <= i)
        Invariant(i <= n + 1)
        # The window never shrinks below 1 and stays ordered ...
        Invariant(a >= 1)
        Invariant(b >= a)
        # ... so the leading entry gains at least 1 per step: index-style, this is the Ensures.
        Invariant(b >= i - 2)
        a, b = b, a + b

    # At exit i = n + 1, so the invariant reads b >= n - 1: one step from the postcondition.
    Assert(b >= n - 1)
    Assert(b >= 1)
    return b
