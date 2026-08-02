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
    # If s contains a letter, the result is s with letter cases swapped.
    Ensures(
        not (any(c.isalpha() for c in s)) or
        (ForAll(
            range(len(s)),
            lambda i: Result()[i] == (s[i].swapcase() if s[i].isalpha() else s[i])
        ))
    )
    # If s contains no letters, the result is the reverse of s.
    Ensures(
        any(c.isalpha() for c in s) or
        (ForAll(
            range(len(s)),
            lambda i: Result()[i] == s[len(s) - 1 - i]
        ))
    )

    ans, has_letter = "", False
    for ch in s:
        Invariant(0 <= len(ans) <= len(s))
        # `has_letter` tracks if any character in the prefix s[0:len(ans)] is a letter.
        Invariant(has_letter == any(c.isalpha() for c in s[0:len(ans)]))
        # `ans` is the case-swapped version of the prefix s[0:len(ans)].
        Invariant(
            ForAll(
                range(len(ans)),
                lambda i: ans[i] == (s[i].swapcase() if s[i].isalpha() else s[i])
            )
        )
        Decreases(len(s) - len(ans))

        if ch.isalpha():
            has_letter = True
            ans += ch.swapcase()
        else:
            ans += ch
            
    # At loop exit, the invariants hold for the entire string.
    Assert(len(ans) == len(s))
    Assert(has_letter == any(c.isalpha() for c in s))
    Assert(
        ForAll(
            range(len(s)),
            lambda i: ans[i] == (s[i].swapcase() if s[i].isalpha() else s[i])
        )
    )
    
    return ans if has_letter else s[::-1]