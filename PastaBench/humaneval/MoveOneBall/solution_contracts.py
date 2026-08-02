from contracts import *


def move_one_ball(arr: list[int]):
    """We have an array 'arr' of N integers arr[1], arr[2], ..., arr[N].The
    numbers in the array will be randomly ordered. Your task is to determine if
    it is possible to get an array sorted in non-decreasing order by performing 
    the following operation on the given array:
        You are allowed to perform right shift operation any number of times.
    
    One right shift operation means shifting all elements of the array by one
    position in the right direction. The last element of the array will be moved to
    the starting position in the array i.e. 0th index. 

    If it is possible to obtain the sorted array by performing the above operation
    then return True else return False.
    If the given array is empty then return True.

    Note: The given list is guaranteed to have unique elements.

    For Example:
    
    move_one_ball([3, 4, 5, 1, 2])==>True
    Explanation: By performin 2 right shift operations, non-decreasing order can
                 be achieved for the given array.
    move_one_ball([3, 5, 4, 1, 2])==>False
    Explanation:It is not possible to get non-decreasing order for the given
                array by performing any number of right shift operations.
                
    """
    # THE POINT: The function checks if `arr` is a cyclic permutation of its sorted version.
    # This is true if and only if there exists a shift `i` such that the shifted
    # array equals the sorted array. The empty array is a special case, defined as true.
    Ensures(Result() == (
        len(arr) == 0 or
        any(arr[i:] + arr[:i] == sorted(arr) for i in range(len(arr)))
    ))

    sorted_arr = sorted(arr)
    if arr == sorted_arr:
        return True

    # After the initial check, we know the 0-shift does not yield the sorted array.
    Assert(arr != sorted_arr)

    for i in range(1, len(arr)):
        # Loop Invariant: The counter `i` is always within the bounds of the iteration range.
        Invariant(1 <= i)
        Invariant(i <= len(arr))

        # Loop Invariant: At the start of iteration `i`, we have confirmed that
        # no cyclic shift from 0 to `i-1` produces the sorted array.
        Invariant(not any(arr[j:] + arr[:j] == sorted_arr for j in range(i)))

        if arr[i:] + arr[:i] == sorted_arr:
            return True

    # After the loop, the invariant implies that no shift from 0 to `len(arr)-1` works.
    Assert(not any(arr[j:] + arr[:j] == sorted_arr for j in range(len(arr))))
    return False