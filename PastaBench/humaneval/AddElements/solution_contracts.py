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
    Requires(1 <= len(arr) <= 100)
    Requires(1 <= k <= len(arr))
    # The result is bounded by k times the maximum absolute value of a 2-digit number.
    Ensures(-99 * k <= Result() <= 99 * k)


    def digits(x: int) -> int:
        # This contract provides the crucial arithmetic meaning of "at most two digits".
        # It's the lemma that allows proving the Ensures of the parent function.
        Ensures((Result() <= 2) == (-99 <= x <= 99))
        s = str(x)
        return len(s) - 1 if s[0] == "-" else len(s)
    return sum(filter(lambda x: digits(x) <= 2, arr[:k]))