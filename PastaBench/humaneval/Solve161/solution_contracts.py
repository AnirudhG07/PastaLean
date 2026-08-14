from typing import *
from contracts import *

def solve(s: str):
    """You are given a string s.
    if s[i] is a letter, reverse its case from lower to upper or vise versa,
    otherwise keep it as it is.
    If the string contains no letters, reverse the string.
    The function should return the resulted string.
    Examples
    solve("1234") = "4321"
    solve("ab") = "AB"
    solve("#a@C") = "#A@c"
    """

    Ensures(len(Result()) == len(s))
    # With a letter present: every position is case-swapped if alphabetic, else copied.
    Ensures(not any(c.isalpha() for c in s)
            or all(not s[i].isalpha() or Result()[i] == s[i].swapcase() for i in range(len(s))))
    Ensures(not any(c.isalpha() for c in s)
            or all(s[i].isalpha() or Result()[i] == s[i] for i in range(len(s))))
    # With no letter at all, the result is the reversal.
    Ensures(any(c.isalpha() for c in s)
            or all(Result()[i] == s[len(s) - 1 - i] for i in range(len(s))))

    ans, has_letter = "", False
    for ch in s:
        Invariant(0 <= len(ans) <= len(s))
        # `has_letter` tracks if any character in the prefix s[0:len(ans)] is a letter.
        Invariant(has_letter == any(c.isalpha() for c in s[0:len(ans)]))
        # `ans` is the case-swapped version of the prefix s[0:len(ans)].
        Invariant(all(not s[i].isalpha() or ans[i] == s[i].swapcase() for i in range(len(ans))))
        Invariant(all(s[i].isalpha() or ans[i] == s[i] for i in range(len(ans))))
        Decreases(len(s) - len(ans))

        if ch.isalpha():
            has_letter = True
            ans += ch.swapcase()
        else:
            ans += ch

    # At loop exit, the invariants hold for the entire string.
    Assert(len(ans) == len(s))
    Assert(has_letter == any(c.isalpha() for c in s))
    Assert(all(not s[i].isalpha() or ans[i] == s[i].swapcase() for i in range(len(s))))
    Assert(all(s[i].isalpha() or ans[i] == s[i] for i in range(len(s))))

    return ans if has_letter else s[::-1]
