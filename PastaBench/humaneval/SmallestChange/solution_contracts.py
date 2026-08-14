from contracts import *

def smallest_change(arr: list[int]):
    """
    Given an array arr of integers, find the minimum number of elements that
    need to be changed to make the array palindromic. A palindromic array is an array that
    is read the same backwards and forwards. In one change, you can change one element to any other element.

    For example:
    smallest_change([1,2,3,5,4,7,9,6]) == 4
    smallest_change([1, 2, 3, 4, 3, 2, 2]) == 1
    smallest_change([1, 2, 3, 2, 1]) == 0
    """
    Ensures(0 <= Result() <= len(arr) // 2)

    arr_reversed, cnt = arr[::-1], 0
    for i in range(len(arr) // 2):
        Invariant(0 <= i <= len(arr) // 2)
        Invariant(0 <= cnt <= i)
        Decreases(len(arr) // 2 - i)

        if arr[i] != arr_reversed[i]:
            cnt += 1
            
    Assert(0 <= cnt <= len(arr) // 2)
    return cnt