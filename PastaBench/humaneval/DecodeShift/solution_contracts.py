from contracts import *


def encode_shift(s: str):
    """
    returns encoded string by shifting every character by 5 in the alphabet.
    """
    Requires(all(ord('a') <= ord(c) and ord(c) <= ord('z') for c in s))
    Ensures(len(Result()) == len(s))
    # The shift stays inside the lowercase alphabet — this is what makes it invertible.
    Ensures(all(ord('a') <= ord(c) and ord(c) <= ord('z') for c in Result()))
    Ensures(all(Result()[i] == chr((ord(s[i]) - ord('a') + 5) % 26 + ord('a'))
                for i in range(len(s))))
    return "".join([chr(((ord(ch) + 5 - ord("a")) % 26) + ord("a")) for ch in s])


def decode_shift(s: str):
    """
    takes as input string encoded with encode_shift function. Returns decoded string.
    """
    Requires(all(ord('a') <= ord(c) and ord(c) <= ord('z') for c in s))
    Ensures(len(Result()) == len(s))
    Ensures(all(ord('a') <= ord(c) and ord(c) <= ord('z') for c in Result()))
    # The point: decode is a genuine left inverse of encode. Re-encoding the answer reproduces
    # the input exactly, i.e. encode_shift ∘ decode_shift is the identity on lowercase strings.
    # This is strictly stronger than any per-character restatement of the body: it forces the
    # two modular shifts to cancel, wrap-around included.
    Ensures(encode_shift(Result()) == s)
    Ensures(all(Result()[i] == chr((ord(s[i]) - ord('a') - 5 + 26) % 26 + ord('a'))
                for i in range(len(s))))
    return "".join([chr((ord(ch) - ord("a") - 5 + 26) % 26 + ord("a")) for ch in s])
