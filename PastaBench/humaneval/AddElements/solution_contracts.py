from contracts import *

def add_elements(arr, k):
    """
    Given a non-empty array of integers arr and an integer k, return
    the sum of the elements with at most two digits from the first k elements of arr.

    Example:

        Input: arr = [111,21,3,4000,5,6,7,8,9], k = 4
        Output: 24 # sum of 21 + 3

    Constraints:
        1. 1 <= len(arr) <= 100
        2. 1 <= k <= len(arr)
    """
    Requires(1 <= len(arr))
    Requires(len(arr) <= 100)
    Requires(1 <= k)
    Requires(k <= len(arr))
    # THE POINT: "at most two digits" is an arithmetic window, -99 <= x <= 99, and at most k
    # elements are ever summed. So the answer is confined to [-99*k, 99*k] — a bound tied to the
    # number of terms, which only follows from decoding the digit test into that window.
    Ensures(-99 * k <= Result())
    Ensures(Result() <= 99 * k)

    def digits(x: int) -> int:
        s = str(x)
        return len(s) - 1 if s[0] == "-" else len(s)

    total = 0
    for i in range(k):
        Invariant(0 <= i)
        Invariant(i <= k)
        # Index-style: after i steps at most i terms have been added, each within [-99, 99].
        Invariant(-99 * i <= total)
        Invariant(total <= 99 * i)
        if digits(arr[i]) <= 2:
            # The bridge the bound rests on: `digits(x) <= 2` spelled arithmetically.
            Assert(-99 <= arr[i])
            Assert(arr[i] <= 99)
            total += arr[i]
    Assert(-99 * k <= total)
    Assert(total <= 99 * k)
    return total
