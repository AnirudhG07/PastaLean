from typing import List
from contracts import *


def separate_paren_groups(paren_string: str) -> List[str]:
    """ Input to this function is a string containing multiple groups of nested parentheses. Your goal is to
    separate those group into separate strings and return the list of those.
    Separate groups are balanced (each open brace is properly closed) and not nested within each other
    Ignore any spaces in the input string.
    >>> separate_paren_groups('( ) (( )) (( )( ))')
    ['()', '(())', '(()())']
    """
    Requires(paren_string.count('(') == paren_string.count(')'))

    Ensures(all(s.count('(') == s.count(')') for s in Result()))
    Ensures("".join(Result()) == paren_string.replace(" ", ""))

    cnt, group, results = 0, "", []
    for ch in paren_string:
        # The concatenation of completed groups and the current group forms a prefix
        # of the input string with spaces removed.
        Invariant(paren_string.replace(" ", "").startswith("".join(results) + group))
        # The counter `cnt` tracks the parenthesis balance of the current `group`.
        Invariant(cnt == group.count('(') - group.count(')'))
        # Every group added to the results list is guaranteed to be balanced.
        Invariant(all(s.count('(') == s.count(')') for s in results))

        if ch == "(": cnt += 1
        if ch == ")": cnt -= 1
        if ch != " ": group += ch
        if cnt == 0:
            if group != "": results.append(group)
            group = ""

    # Because the input string is balanced (from Requires), the final count must be 0,
    # which implies the last group was completed and reset.
    Assert(group == "")
    return results