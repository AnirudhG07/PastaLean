from contracts import *


def encode_shift(s: str):
    """
    returns encoded string by shifting every character by 5 in the alphabet.
    """
    Requires(all(ord('a') <= ord(c) <= ord('z') for c in s))
    Ensures(len(Result()) == len(s))
    Ensures(all(ord('a') <= ord(c) <= ord('z') for c in Result()))
    Ensures(all(
        ord(Result()[i]) == ((ord(s[i]) - ord('a') + 5) % 26) + ord('a')
        for i in range(len(s))
    ))
    return "".join([chr(((ord(ch) + 5 - ord("a")) % 26) + ord("a")) for ch in s])


def decode_shift(s: str):
    """
    takes as input string encoded with encode_shift function. Returns decoded string.
    """
    Requires(all(ord('a') <= ord(c) <= ord('z') for c in s))
    Ensures(len(Result()) == len(s))
    Ensures(all(ord('a') <= ord(c) <= ord('z') for c in Result()))
    Ensures(all(
        ord(Result()[i]) == ((ord(s[i]) - ord('a') - 5 + 26) % 26) + ord('a')
        for i in range(len(s))
    ))
    return "".join([chr((ord(ch) - ord("a") - 5 + 26) % 26 + ord("a")) for ch in s])