from typing import *
from contracts import *

def cycpattern_check(a: str, b: str):
    """You are given 2 words. You need to return True if the second word or any of its rotations is a substring in the first word
    cycpattern_check("abcd","abd") => False
    cycpattern_check("hello","ell") => True
    cycpattern_check("whassup","psus") => False
    cycpattern_check("abab","baa") => True
    cycpattern_check("efef","eeff") => False
    cycpattern_check("himenss","simen") => True

    """
    Ensures(Result() == (b == "" or any(b[k:] + b[:k] in a for k in range(len(b)))))

    if a == b:
        return True
    if b == "":
        return True
    for i in range(0, len(b)):
        Invariant(0 <= i <= len(b))
        # Accumulator-style invariant: if we are at step `i`, it's because
        # none of the previous rotations (0..i-1) were found in `a`.
        Invariant(not any(b[k:] + b[:k] in a for k in range(i)))
        Decreases(len(b) - i)
        if b[i:] + b[:i] in a:
            return True
    # Bridge from loop invariant to postcondition for the `False` case.
    # When the loop finishes, `i == len(b)`, so the invariant implies
    # that no rotation was found.
    Assert(not any(b[k:] + b[:k] in a for k in range(len(b))))
    return False