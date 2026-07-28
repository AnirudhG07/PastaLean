from contracts import *


def maxNumber(n: int) -> int:
    Requires(n > 0)
    # The result is (1 << (n.bit_length() - 1)) - 1, i.e. the largest number with all lower bits set below the highest bit of n.
    Ensures(Result() == (1 << (n.bit_length() - 1)) - 1)
    return (1 << n.bit_length() - 1) - 1