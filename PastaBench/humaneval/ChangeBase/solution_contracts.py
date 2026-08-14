from contracts import *


def change_base(x: int, base: int):
    """Change numerical base of input number x to base.
    return string representation after the conversion.
    base numbers are less than 10.
    >>> change_base(8, 3)
    '22'
    >>> change_base(8, 2)
    '1000'
    >>> change_base(7, 2)
    '111'
    """
    Requires(x >= 0)
    # `str(x % base)` is a single character only while the base has one-character digits.
    Requires(2 <= base)
    Requires(base < 10)

    # THE POINT: the answer really is a base-`base` numeral. Every character it contains is a
    # legal digit of that base — which is true only because each character came from `x % base`,
    # and it is never the empty string. (Deliberately phrased without mentioning `x`: the loop
    # destroys `x`, so a postcondition about `x` would be read against the *final* x = 0.)
    Ensures(len(Result()) >= 1)
    Ensures(all(0 <= int(c) and int(c) < base for c in Result()))

    if x == 0:
        return "0"

    # Falls through the guard with x != 0, and x >= 0 by the precondition.
    Assert(x > 0)
    ret = ""
    while x != 0:
        Invariant(x > 0)
        # Every character accumulated so far is a remainder mod `base`, hence a legal digit.
        Invariant(all(0 <= int(c) and int(c) < base for c in ret))
        Decreases(x)
        ret = str(x % base) + ret
        x //= base

    # x started strictly positive, so the body ran at least once and prepended a digit.
    Assert(len(ret) >= 1)
    Assert(all(0 <= int(c) and int(c) < base for c in ret))
    return ret
