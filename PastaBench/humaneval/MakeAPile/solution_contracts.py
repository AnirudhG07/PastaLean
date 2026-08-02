from contracts import *


def make_a_pile(n: int) -> list[int]:
    """
    Given a positive integer n, you have to make a pile of n levels of stones.
    The first level has n stones.
    The number of stones in the next level is:
        - the next odd number if n is odd.
        - the next even number if n is even.
    Return the number of stones in each level in a list, where element at index
    i represents the number of stones in the level (i+1).

    Examples:
    >>> make_a_pile(3)
    [3, 5, 7]
    """
    Requires(n >= 0)
    Ensures(len(Result()) == n)
    # The list elements form an arithmetic progression starting at n with a step of 2.
    Ensures(n == 0 or Result()[0] == n)
    Ensures(n == 0 or Result()[n - 1] == n + 2 * (n - 1))

    ans, num = [], n
    for i in range(n):
        Invariant(0 <= i <= n)
        Invariant(len(ans) == i)
        Invariant(num == n + 2 * i)
        # At the start of iteration i, the list `ans` contains the results of the
        # previous i iterations, so its last element corresponds to step i-1.
        Invariant(i == 0 or ans[i - 1] == n + 2 * (i - 1))

        ans.append(num)
        num += 2
    return ans