from typing import List
from contracts import *


def count_depth(s: str) -> int:
    Requires(all(c == '(' or c == ')' for c in s))
    # The point: the returned number IS the maximum nesting depth of s — it dominates the depth
    # of every prefix, and some prefix actually attains it. (Upper bound + attained = maximum.)
    Ensures(all(s[:k].count('(') - s[:k].count(')') <= Result() for k in range(len(s) + 1)))
    Ensures(any(s[:k].count('(') - s[:k].count(')') == Result() for k in range(len(s) + 1)))
    max_depth, cnt = 0, 0
    for ch in s:
        # max_depth is the running maximum of the prefix depths, so it dominates cnt and, since
        # it starts at the depth of the empty prefix, is never negative.
        Invariant(max_depth >= 0)
        Invariant(cnt <= max_depth)
        if ch == "(": cnt += 1
        if ch == ")": cnt -= 1
        max_depth = max(max_depth, cnt)
    return max_depth


def parse_nested_parens(paren_string: str) -> List[int]:
    """ Input to this function is a string represented multiple groups for nested parentheses separated by spaces.
    For each of the group, output the deepest level of nesting of parentheses.
    E.g. (()()) has maximum two levels of nesting while ((())) has three.

    >>> parse_nested_parens('(()()) ((())) () ((())()())')
    [2, 3, 1, 3]
    """
    Requires(all(c == '(' or c == ')' or c == ' ' for c in paren_string))
    # One entry per non-empty space-separated group, in order.
    Ensures(len(Result()) == len([g for g in paren_string.split(" ") if g != ""]))
    # Every group opens at least once, so its deepest level is at least 1.
    Ensures(all(x >= 1 for x in Result()))
    # The point: entry i is the maximum nesting depth of group i — the largest bracket depth
    # (#'(' minus #')') reached by any prefix of that group.
    Ensures(Result() == [max([g[:k].count('(') - g[:k].count(')') for k in range(len(g) + 1)])
                         for g in paren_string.split(" ") if g != ""])

    return [count_depth(s) for s in paren_string.split(" ") if s != ""]
