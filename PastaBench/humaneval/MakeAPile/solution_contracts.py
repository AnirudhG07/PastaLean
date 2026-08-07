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
    # THE POINT: n levels holding the arithmetic progression n, n+2, …, n+2(n-1). Length pins the
    # level count; the total pins the progression's closed form, n*n + n*(n-1) = 2n^2 - n.
    Ensures(len(Result()) == n)
    Ensures(sum(Result()) == 2 * n * n - n)

    ans, num = [], n
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(len(ans) == i)
        Invariant(num == n + 2 * i)
        # Index-style: after i levels the running total is i*n + i*(i-1), which at i == n IS the
        # postcondition 2n^2 - n.
        Invariant(sum(ans) == i * n + i * (i - 1))

        ans.append(num)
        num += 2
    return ans
