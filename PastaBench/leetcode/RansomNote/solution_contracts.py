from contracts import *
from collections import Counter


def canConstruct(ransomNote: str, magazine: str) -> bool:
    """
    Determines if the ransom note can be constructed from the characters in the magazine.
    This is true if and only if the magazine contains at least as many instances of
    each character as the ransom note requires.
    """
    Ensures(Result() == all(ransomNote.count(c) <= magazine.count(c) for c in set(ransomNote)))

    cnt = Counter(magazine)
    for c in ransomNote:
        cnt[c] -= 1
        if cnt[c] < 0:
            return False
    return True