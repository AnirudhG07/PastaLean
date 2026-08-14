from contracts import *


def even_odd_count(num: int):
    """Given an integer. return a tuple that has the number of even and odd digits respectively.

     Example:
        even_odd_count(-12) ==> (1, 1)
        even_odd_count(123) ==> (1, 2)
    """
    Ensures(Result()[0] >= 0)
    Ensures(Result()[1] >= 0)
    Ensures(Result()[0] + Result()[1] == (len(str(num)) - 1 if num < 0 else len(str(num))))

    s = str(num)
    even, odd = 0, 0
    # The loop is changed to use `enumerate` to expose the loop counter `i`,
    # which is necessary for writing an effective loop invariant.
    for i, ch in enumerate(s):
        Invariant(0 <= i <= len(s))
        Invariant(even >= 0)
        Invariant(odd >= 0)
        # The sum of counts `even + odd` equals the number of digits processed so far.
        # If num is negative, the first character is '-' (a non-digit), so the count is `i-1` for `i > 0`.
        Invariant((num >= 0 and even + odd == i) or
                  (num < 0 and even + odd == (i - 1 if i > 0 else 0)))

        if ch in "02468":
            even += 1
        if ch in "13579":
            odd += 1

    Assert(even + odd == (len(s) - 1 if num < 0 else len(s)))
    return even, odd