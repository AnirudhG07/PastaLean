from typing import List
from contracts import *


def parse_nested_parens(paren_string: str) -> List[int]:
    """ Input to this function is a string represented multiple groups for nested parentheses separated by spaces.
    For each of the group, output the deepest level of nesting of parentheses.
    E.g. (()()) has maximum two levels of nesting while ((())) has three.

    >>> parse_nested_parens('(()()) ((())) () ((())()())')
    [2, 3, 1, 3]
    """
    Ensures(all(x >= 0 for x in Result()))

    
    def count_depth(s: str) -> int:
        Ensures(Result() >= 0)
        max_depth, cnt = 0, 0
        for ch in s:
            Invariant(max_depth >= 0)
            if ch == "(": cnt += 1
            if ch == ")": cnt -= 1
            max_depth = max(max_depth, cnt)
        return max_depth
    
    return [count_depth(s) for s in paren_string.split(" ") if s != ""]