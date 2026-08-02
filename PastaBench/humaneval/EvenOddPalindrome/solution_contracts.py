from contracts import *


def even_odd_palindrome(n):
    """
    Given a positive integer n, return a tuple that has the number of even and odd
    integer palindromes that fall within the range(1, n), inclusive.
    """
    Requires(n >= 1)
    # Deep counting law: each of the n integers 1..n is counted at most once (only if it is a
    # palindrome, and then into exactly one of the two buckets), so the two palindrome counts
    # together never exceed n.
    Ensures(Result()[0] + Result()[1] <= n)
    odd_cnt, even_cnt = 0, 0
    for i in range(1, n + 1):
        Invariant(odd_cnt + even_cnt <= i - 1)
        if str(i) == str(i)[::-1]:
            if i % 2 == 1:
                odd_cnt += 1
            else:
                even_cnt += 1
    return even_cnt, odd_cnt
