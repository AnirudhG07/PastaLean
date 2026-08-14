from contracts import *


def encode_cyclic(s: str):
    """
    returns encoded string by cycling groups of three characters.
    """
    # Regrouping into blocks of three and rotating within each block is a permutation of
    # the characters: same length, same multiset.
    Ensures(len(Result()) == len(s))
    Ensures(sorted(Result()) == sorted(s))
    # split string to groups. Each of length 3.
    groups = [s[(3 * i):min((3 * i + 3), len(s))] for i in range((len(s) + 2) // 3)]
    # cycle elements in each group. Unless group has fewer elements than 3.
    groups = [(group[1:] + group[0]) if len(group) == 3 else group for group in groups]
    return "".join(groups)


def decode_cyclic(s: str):
    """
    takes as input string encoded with encode_cyclic function. Returns decoded string.
    """
    # THE POINT: decode is the two-sided inverse of encode. `encode_cyclic` rotates each
    # 3-block left, `decode_cyclic` rotates it right, so composing them is the identity on
    # every string -- this is strictly stronger than any length/multiset statement.
    Ensures(encode_cyclic(Result()) == s)
    Ensures(len(Result()) == len(s))
    Ensures(sorted(Result()) == sorted(s))
    groups = [s[(3 * i):min((3 * i + 3), len(s))] for i in range((len(s) + 2) // 3)]
    groups = [(group[2] + group[:2]) if len(group) == 3 else group for group in groups]
    return "".join(groups)
