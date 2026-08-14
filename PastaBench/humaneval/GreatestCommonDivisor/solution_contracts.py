from contracts import *


def greatest_common_divisor(a: int, b: int) -> int:
    """ Return a greatest common divisor of two integers a and b
    >>> greatest_common_divisor(3, 5)
    1
    >>> greatest_common_divisor(25, 15)
    5
    """
    Ensures((Result() == 0) == (a == 0 and b == 0))
    Ensures(a % Result() == 0 if Result() != 0 else a == 0)
    Ensures(b % Result() == 0 if Result() != 0 else b == 0)

    def query_gcd(a: int, b: int) -> int:
        Ensures((Result() == 0) == (a == 0 and b == 0))
        Ensures(a % Result() == 0 if Result() != 0 else a == 0)
        Ensures(b % Result() == 0 if Result() != 0 else b == 0)
        return a if b == 0 else query_gcd(b, a % b)
    return query_gcd(a, b)