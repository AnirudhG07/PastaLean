from contracts import *


def is_nested(string):
    '''
    Create a function that takes a string as input which contains only square brackets.
    The function should return True if and only if there is a valid subsequence of brackets
    where at least one bracket in the subsequence is nested.

    is_nested('[[]]') ➞ True
    is_nested('[]]]]]]][[[[[]') ➞ False
    is_nested('[][]') ➞ False
    is_nested('[]') ➞ False
    is_nested('[[][]]') ➞ True
    is_nested('[[]][[') ➞ True
    '''
    Requires(all(c == '[' or c == ']' for c in string))
    # The point, stated as the index pair the two loops search for: the scan reports True exactly
    # when some start i carries two openers back to back (string[i] and string[i+1] are both '[')
    # AND that start is eventually closed off — some j > i makes string[i:j+1] balanced. The
    # adjacency is what forces the depth to reach 2 before the first return to depth 0, which is
    # the `max_nest >= 2` test; the balanced j is the `cnt == 0` test.
    Ensures(Result() == any(
        string[i] == '[' and string[i + 1] == '['
        and any(string[i:j + 1].count('[') == string[i:j + 1].count(']')
                for j in range(i + 1, len(string)))
        for i in range(len(string) - 1)))

    for i in range(len(string)):
        Invariant(0 <= i)
        Invariant(i <= len(string))
        if string[i] == "]": continue

        Assert(0 <= i)
        Assert(i < len(string))
        Assert(string[i] == '[')
        cnt, max_nest = 0, 0
        for j in range(i, len(string)):
            Invariant(0 <= i)
            Invariant(i < len(string))
            Invariant(i <= j)
            Invariant(j <= len(string))

            # cnt is exactly the bracket depth of the window already consumed, string[i:j].
            Invariant(cnt == string[i:j].count('[') - string[i:j].count(']'))

            # max_nest is the running maximum of those depths, so it dominates cnt and is >= 0.
            Invariant(max_nest >= 0)
            Invariant(cnt <= max_nest)

            Decreases(len(string) - j)

            if string[j] == "[":
                cnt += 1
            else:
                cnt -= 1
            max_nest = max(max_nest, cnt)

            if cnt == 0:
                # string[i:j+1] is balanced. Depth 2 was reached inside it iff string[i+1] was
                # also an opener, which is exactly the nesting we are looking for.
                if max_nest >= 2:
                    return True
                break
    return False
