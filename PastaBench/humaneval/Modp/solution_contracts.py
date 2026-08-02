from contracts import *


def modp(n: int, p: int):
    """Return 2^n modulo p (be aware of numerics).
    >>> modp(3, 5)
    3
    >>> modp(1101, 101)
    2
    >>> modp(0, 101)
    1
    >>> modp(3, 11)
    8
    >>> modp(100, 101)
    1
    """
    Requires(n >= 0)
    Requires(p > 0)
    n_0 = n
    Ensures(Result() == pow(2, n_0, p))

    res, x = 1, 2
    while n != 0:
        Invariant(n >= 0)
        Invariant((res * pow(x, n)) % p == pow(2, n_0, p))
        Decreases(n)

        if n % 2 == 1:
            res = res * x % p
        x = x * x % p
        n //= 2

    Assert(res % p == pow(2, n_0, p))
    return res % p