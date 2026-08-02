from contracts import *
from typing import List


def string_xor(a: str, b: str) -> str:
    """ Input are two strings a and b consisting only of 1s and 0s.
    Perform binary XOR on these inputs and return result also as a string.
    >>> string_xor('010', '110')
    '100'
    """
    Requires(len(a) == len(b))
    Requires(all(c in '01' for c in a))
    Requires(all(c in '01' for c in b))
    Ensures(len(Result()) == len(a))
    Ensures(all(c in '01' for c in Result()))

    return "".join(str(int(a[i]) ^ int(b[i])) for i in range(len(a)))