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
    # Position k holds the value for i = k + 1. i odd (k even) => the triangular number
    # 1 + ... + i, stated division-free as 2 * ans[k] == (k+1) * (k+2).
    Ensures(all(2 * Result()[k] == (k + 1) * (k + 2) for k in range(n) if k % 2 == 0))
    # i even (k odd) => i!, stated by its own recurrence i! = (i-2)! * (i-1) * i, with 2! = 2 as base.
    Ensures(n < 2 or Result()[1] == 2)
    Ensures(all(Result()[k] == Result()[k - 2] * k * (k + 1) for k in range(3, n) if k % 2 == 1))

    if n == 0: return []
    if n == 1: return [1]
    if n == 2: return [1, 2]

    ans = [1, 2]
    for i in range(3, n + 1):
        Decreases(n + 1 - i)
        Invariant(3 <= i)
        Invariant(i <= n + 1)
        Invariant(len(ans) == i - 1)
        Invariant(ans[1] == 2)
        Invariant(all(2 * ans[k] == (k + 1) * (k + 2) for k in range(len(ans)) if k % 2 == 0))
        Invariant(all(ans[k] == ans[k - 2] * k * (k + 1) for k in range(3, len(ans)) if k % 2 == 1))
        # ans[-2] is ans[i-3]; this is the bound that makes that read safe.
        Assert(0 <= i - 3 < len(ans))

        if i % 2 == 1:
            ans.append(ans[-2] + (i - 1) + i)
        else:
            ans.append(ans[-2] * (i - 1) * i)

    Assert(len(ans) == n)
    return ans
