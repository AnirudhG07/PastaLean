from contracts import *


def correct_bracketing(brackets: str):
    """ brackets is a string of "<" and ">".
    return True if every opening bracket has a corresponding closing bracket.

    >>> correct_bracketing("<")
    False
    >>> correct_bracketing("<>")
    True
    >>> correct_bracketing("<<><>>")
    True
    >>> correct_bracketing("><<>")
    False
    """
    Requires(all(c == '<' or c == '>' for c in brackets))
    # If the function returns True, the total number of opening and closing brackets must be equal.
    Ensures((not Result()) or (brackets.count('<') == brackets.count('>')))

    cnt = 0
    for x in brackets:
        # The running count of open brackets must never be negative. This captures the
        # core property that for any prefix, the number of '<' is not less than
        # the number of '>'.
        Invariant(cnt >= 0)

        if x == "<":
            cnt += 1
        if x == ">":
            cnt -= 1
        if cnt < 0:
            return False

    # After the loop, the counter `cnt` reflects the total balance of the entire string.
    # This assertion bridges the loop's result to a property of the input.
    Assert(cnt == brackets.count('<') - brackets.count('>'))
    return cnt == 0