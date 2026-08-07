from contracts import *
from typing import List


def string_xor(a: str, b: str) -> str:
    """ Input are two strings a and b consisting only of 1s and 0s.
    Perform binary XOR on these inputs and return result also as a string.
    >>> string_xor('010', '110')
    '100'
    """
    Requires(len(a) == len(b))
    Requires(all(c == '0' or c == '1' for c in a))
    Requires(all(c == '0' or c == '1' for c in b))
    Ensures(len(Result()) == len(a))
    Ensures(len(Result()) == len(b))
    Ensures(all(c == '0' or c == '1' for c in Result()))
    # The point: the output really is the bitwise XOR — position i is '0' exactly when the two
    # input bits agree there, and '1' exactly when they differ. This elementwise clause is what
    # distinguishes XOR from any other length-preserving bit map.
    Ensures(all(Result()[i] == ('0' if a[i] == b[i] else '1') for i in range(len(a))))

    return "".join(str(int(a[i]) ^ int(b[i])) for i in range(len(a)))
