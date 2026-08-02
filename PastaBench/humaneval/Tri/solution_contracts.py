from contracts import *


def tri(n):
    """Everyone knows Fibonacci sequence, it was studied deeply by mathematicians in 
    the last couple centuries. However, what people don't know is Tribonacci sequence.
    Tribonacci sequence is defined by the recurrence:
    tri(1) = 3
    tri(n) = 1 + n / 2, if n is even.
    tri(n) =  tri(n - 1) + tri(n - 2) + tri(n + 1), if n is odd.
    For example:
    tri(2) = 1 + (2 / 2) = 2
    tri(4) = 3
    tri(3) = tri(2) + tri(1) + tri(4)
           = 2 + 3 + 3 = 8 
    You are given a non-negative integer number n, you have to a return a list of the 
    first n + 1 numbers of the Tribonacci sequence.
    Examples:
    tri(3) = [1, 3, 2, 8]
    """
    Requires(n >= 0)
    
    Ensures(len(Result()) == n + 1)
    # The implementation implies tri(0) = 1, which we capture here.
    Ensures(Result()[0] == 1)
    Ensures(n < 1 or Result()[1] == 3)
    # The main property: all elements from index 2 onwards obey the recurrence.
    Ensures(n < 2 or all(
        (k % 2 == 0 and Result()[k] == 1 + k / 2) or
        (k % 2 != 0 and Result()[k] == Result()[k-1] + Result()[k-2] + 1 + (k+1) / 2)
        for k in range(2, n + 1)
    ))

    if n == 0: return [1]
    if n == 1: return [1, 3]

    Assert(n >= 2)
    ans = [1, 3]
    for i in range(2, n + 1):
        Invariant(2 <= i <= n + 1)
        Invariant(len(ans) == i)
        # The computed prefix of the sequence must satisfy the definition.
        Invariant(ans[0] == 1)
        Invariant(ans[1] == 3)
        Invariant(all(
            (k % 2 == 0 and ans[k] == 1 + k / 2) or
            (k % 2 != 0 and ans[k] == ans[k-1] + ans[k-2] + 1 + (k+1) / 2)
            for k in range(2, i)
        ))
        Decreases(n + 1 - i)
        
        if i % 2 == 0:
            ans.append(1 + i / 2)
        else:
            ans.append(ans[-1] + ans[-2] + 1 + (i + 1) / 2)

    # After the loop, the invariant holds for i = n + 1, which implies the postconditions.
    Assert(len(ans) == n + 1)
    Assert(ans[0] == 1 and ans[1] == 3)
    Assert(all(
        (k % 2 == 0 and ans[k] == 1 + k / 2) or
        (k % 2 != 0 and ans[k] == ans[k-1] + ans[k-2] + 1 + (k+1) / 2)
        for k in range(2, n + 1)
    ))
    return ans