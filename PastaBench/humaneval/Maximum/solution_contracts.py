from contracts import *

def maximum(arr, k):
    """
    Given an array arr of integers and a positive integer k, return a sorted list 
    of length k with the maximum k numbers in arr.

    Example 1:

        Input: arr = [-3, -4, 5], k = 3
        Output: [-4, -3, 5]

    Example 2:

        Input: arr = [4, -4, 4], k = 2
        Output: [4, 4]

    Example 3:

        Input: arr = [-3, 2, 1, 2, -1, -2, 1], k = 1
        Output: [2]

    Note:
        1. The length of the array will be in the range of [1, 1000].
        2. The elements in the array will be in the range of [-1000, 1000].
        3. 0 <= k <= len(arr)
    """
    Requires(0 <= k)
    Requires(k <= len(arr))

    # The result has length k.
    Ensures(len(Result()) == k)

    # The result is sorted in non-decreasing order.
    Ensures(all(Result()[i] <= Result()[i+1] for i in range(k - 1)))

    # The elements of the result form a sub-multiset of the original array.
    Ensures(all(Result().count(x) <= arr.count(x) for x in set(Result())))

    # Every element in the result is at least as large as the k-th largest
    # element in the original array. This pins down which elements are chosen.
    # We guard with k > 0 because `sorted(arr)[len(arr) - k]` is only meaningful
    # if the result is non-empty and `k <= len(arr)`. Our Requires covers this.
    Ensures(k == 0 or all(x >= sorted(arr)[len(arr) - k] for x in Result()))


    return sorted(sorted(arr)[::-1][:k])