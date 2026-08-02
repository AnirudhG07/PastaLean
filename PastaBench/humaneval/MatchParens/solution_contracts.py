from contracts import *

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
    Requires(isinstance(lst[0], str))
    Requires(isinstance(lst[1], str))
    # Per the docstring, the inputs are guaranteed to only contain parentheses.
    # This is a key assumption for the logic of valid_parens.
    Requires(all(c == '(' or c == ')' for c in lst[0]))
    Requires(all(c == '(' or c == ')' for c in lst[1]))
    Ensures(Result() == 'Yes' or Result() == 'No')


    def valid_parens(s: str) -> bool:
        # This helper is only called with strings composed of parentheses,
        # due to the Requires contracts on the outer function.
        Assume(all(c == '(' or c == ')' for c in s))
        cnt = 0
        for ch in s:
            # The invariant is that the balance of parentheses is never negative
            # for any prefix of the string processed so far.
            Invariant(cnt >= 0)
            cnt = cnt + 1 if ch == "(" else cnt - 1
            if cnt < 0:
                return False
        # The loop invariant implies the final count is non-negative.
        Assert(cnt >= 0)
        # This asserts that the final count reflects the total balance of the string.
        # This is provable by induction over the loop, given the assumption
        # that the string only contains '(' and ')'.
        Assert(cnt == s.count('(') - s.count(')'))
        return cnt == 0
    return "Yes" if valid_parens(lst[0] + lst[1]) or valid_parens(lst[1] + lst[0]) else "No"