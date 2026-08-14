from contracts import *


def correct_bracketing(brackets: str):
    """ brackets is a string of "(" and ")".
    return True if every opening bracket has a corresponding closing bracket.

    >>> correct_bracketing("(")
    False
    >>> correct_bracketing("()")
    True
    >>> correct_bracketing("(()())")
    True
    >>> correct_bracketing(")(()")
    False
    """

    Requires(all(c == '(' or c == ')' for c in brackets))
    # If the function returns True, the total number of opening and closing brackets must be equal.
    Ensures((not Result()) or (brackets.count('(') == brackets.count(')')))

    cnt = 0
    for x in brackets:
        # The running balance of open minus closed brackets must never be negative.
        # This is the key property for a valid prefix.
        Invariant(cnt >= 0)
        # The balance is also bounded by the total string length.
        Invariant(cnt <= len(brackets))

        if x == "(": cnt += 1
        if x == ")": cnt -= 1
        if cnt < 0: return False

    # If the loop completes, it means no prefix had a negative balance.
    # At this point, `cnt` holds the total balance of the entire string.
    Assert(cnt == brackets.count('(') - brackets.count(')'))

    # The string is correctly bracketed iff the total balance is zero.
    return cnt == 0