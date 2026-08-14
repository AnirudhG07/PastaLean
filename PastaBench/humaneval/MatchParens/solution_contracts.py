from contracts import *


def valid_parens(s: str) -> bool:
    Requires(all(c == '(' or c == ')' for c in s))
    # The depth argument in full: s is good exactly when no prefix has more ')' than '(' and the
    # two totals agree.
    Ensures(Result() == (
        s.count('(') == s.count(')')
        and all(s[:k].count('(') >= s[:k].count(')') for k in range(len(s) + 1))))
    cnt = 0
    for ch in s:
        # The scan returns the moment the depth would go negative, so it is non-negative here.
        Invariant(cnt >= 0)
        cnt = cnt + 1 if ch == "(" else cnt - 1
        if cnt < 0:
            return False
    Assert(cnt == s.count('(') - s.count(')'))
    return cnt == 0


def match_parens(lst):
    '''
    You are given a list of two strings, both strings consist of open
    parentheses '(' or close parentheses ')' only.
    Your job is to check if it is possible to concatenate the two strings in
    some order, that the resulting string will be good.
    A string S is considered to be good if and only if all parentheses in S
    are balanced. For example: the string '(())()' is good, while the string
    '())' is not.
    Return 'Yes' if there's a way to make a good string, and return 'No' otherwise.

    Examples:
    match_parens(['()(', ')']) == 'Yes'
    match_parens([')', ')']) == 'No'
    '''
    Requires(len(lst) == 2)
    # Per the docstring, the inputs are guaranteed to only contain parentheses.
    Requires(all(c == '(' or c == ')' for c in lst[0]))
    Requires(all(c == '(' or c == ')' for c in lst[1]))
    # The point: 'Yes' exactly when one of the two concatenation orders is balanced, spelled out
    # with the same running-depth argument the scan uses (no prefix goes negative, totals match)
    # rather than by naming valid_parens.
    Ensures(Result() == ("Yes" if any(
        t.count('(') == t.count(')')
        and all(t[:k].count('(') >= t[:k].count(')') for k in range(len(t) + 1))
        for t in [lst[0] + lst[1], lst[1] + lst[0]]) else "No"))
    return "Yes" if valid_parens(lst[0] + lst[1]) or valid_parens(lst[1] + lst[0]) else "No"
