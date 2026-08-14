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
    # The point: "balanced" is exactly the running-depth condition the scan checks — the depth
    # of every prefix (#'<' minus #'>') stays non-negative, and the depth of the whole string
    # is zero. Both halves are needed: '><<>' has total depth 0 but a negative prefix, and
    # '<<' never dips but ends above zero.
    Ensures(Result() == (
        brackets.count('<') == brackets.count('>')
        and all(brackets[:k].count('<') >= brackets[:k].count('>')
                for k in range(len(brackets) + 1))))

    cnt = 0
    for x in brackets:
        # The scan bails out the instant the depth would go negative, so on every iteration
        # reached the depth so far is still non-negative.
        Invariant(cnt >= 0)

        if x == "<":
            cnt += 1
        if x == ">":
            cnt -= 1
        if cnt < 0:
            return False

    # Falling out of the loop means no prefix went negative, and cnt is the whole-string depth.
    Assert(cnt == brackets.count('<') - brackets.count('>'))
    return cnt == 0
