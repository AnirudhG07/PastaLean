from contracts import *


FIX = """
Add more test cases.
"""

def vowels_count(s):
    """Write a function vowels_count which takes a string representing
    a word as input and returns the number of vowels in the string.
    Vowels in this case are 'a', 'e', 'i', 'o', 'u'. Here, 'y' is also a
    vowel, but only when it is at the end of the given word.

    Example:
    >>> vowels_count("abcde")
    2
    >>> vowels_count("ACEDY")
    3
    """
    Ensures(0 <= Result())
    Ensures(Result() <= len(s))

    if s == "": return 0
    Assert(len(s) >= 1)

    cnt = len(list(filter(lambda ch: ch in "aeiouAEIOU", s)))
    Assert(0 <= cnt <= len(s))

    if s[-1] in "yY":
        # The filter for `cnt` does not include 'y' or 'Y'.
        # So if s[-1] is 'y' or 'Y', it was not included in the count.
        # This means `cnt` is at most the number of other characters, len(s) - 1.
        Assert(cnt <= len(s) - 1)
        cnt += 1

    Assert(0 <= cnt <= len(s))
    return cnt