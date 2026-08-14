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
    # THE POINT: the result IS 2**n reduced mod p — stated division-free as "canonical residue in
    # [0, p) that is congruent to 2**n". (`pow(2, n_0, p)` is not usable here: the runtime's modular
    # `pow` is a fuelled square-and-multiply with no equational theory, so a spec written with it is
    # unprovable rather than merely hard.)
    Ensures(0 <= Result())
    Ensures(Result() < p)
    Ensures((Result() - 2 ** n_0) % p == 0)

    res, x = 1, 2
    while n != 0:
        Invariant(n >= 0)
        # Square-and-multiply's carried equation: res * x**n stays congruent to 2**n_0 mod p.
        Invariant((res * x ** n - 2 ** n_0) % p == 0)
        Decreases(n)

        if n % 2 == 1:
            res = res * x % p
        x = x * x % p
        n //= 2

    return res % p
