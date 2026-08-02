from contracts import *

def f(n):
    """ Implement the function f that takes n as a parameter,
    and returns a list of size n, such that the value of the element at index i is the factorial of i if i is even
    or the sum of numbers from 1 to i otherwise.
    i starts from 1.
    the factorial of i is the multiplication of the numbers from 1 to i (1 * 2 * ... * i).
    Example:
    f(5) == [1, 2, 6, 24, 15]
    """
    Requires(n >= 0)
    Ensures(len(Result()) == n)
    Ensures(n < 1 or Result()[0] == 1)
    Ensures(n < 2 or Result()[1] == 2)


    if n == 0: return []
    if n == 1: return [1]
    if n == 2: return [1, 2]

    Assert(n >= 3)
    ans = [1, 2]
    for i in range(3, n + 1):
        Decreases(n + 1 - i)
        Invariant(3 <= i)
        Invariant(i <= n + 1)
        Invariant(len(ans) == i - 1)
        Invariant(ans[0] == 1)
        Invariant(ans[1] == 2)
        # Bridge assertion to prove safe indexing of ans[-2], which is ans[i-3].
        Assert(0 <= i - 3 < len(ans))

        if i % 2 == 1:
            ans.append(ans[-2] + (i - 1) + i)
        else:
            ans.append(ans[-2] * (i - 1) * i)

    Assert(len(ans) == n)
    return ans