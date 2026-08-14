from contracts import *


def fix_spaces(text):
    """
    Given a string text, replace all spaces in it with underscores, 
    and if a string has more than 2 consecutive spaces, 
    then replace all consecutive spaces with - 
    
    fix_spaces("Example") == "Example"
    fix_spaces("Example 1") == "Example_1"
    fix_spaces(" Example 2") == "_Example_2"
    fix_spaces(" Example   3") == "_Example-3"
    """
    Ensures(len(Result()) <= len(text))
    Ensures(" " not in Result())

    ans = text
    for i in range(len(text), 2, -1):
        Invariant(2 < i <= len(text))
        # Each replacement of a run of i>=3 spaces with a single "-"
        # either shortens the string or leaves its length unchanged.
        Invariant(len(ans) <= len(text))
        # At the start of iteration i, all runs of spaces of length i+1
        # or more have been replaced in previous iterations.
        Invariant(" " * (i + 1) not in ans)
        Decreases(i - 2)

        ans = ans.replace(" " * i, "-")

    # The loop removes all runs of 3 or more spaces.
    Assert("   " not in ans)
    Assert(len(ans) <= len(text))

    return ans.replace(" ", "_")