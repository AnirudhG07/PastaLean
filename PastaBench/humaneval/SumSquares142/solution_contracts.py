from contracts import *


def sum_squares(lst):
    """"
    This function will take a list of integers. For all entries in the list, the function shall square the integer entry if its index is a 
    multiple of 3 and will cube the integer entry if its index is a multiple of 4 and not a multiple of 3. The function will not 
    change the entries in the list whose indexes are not a multiple of 3 or 4. The function shall then return the sum of all entries. 
    
    Examples:
    For lst = [1,2,3] the output should be 6
    For lst = []  the output should be 0
    For lst = [-1,-5,2,-1,-5]  the output should be -126
    """
    # The exact index-dependent fold: square at index % 3 == 0, cube at index % 4 == 0 (and not
    # % 3), the entry itself otherwise. Note index 0 is a multiple of BOTH, and the `elif` in the
    # code makes the square win — the nesting order here mirrors that.
    Ensures(Result() == sum(
        lst[k] ** 2 if k % 3 == 0 else (lst[k] ** 3 if k % 4 == 0 else lst[k])
        for k in range(len(lst))
    ))
    Ensures(len(lst) > 0 or Result() == 0)

    ans = 0
    for i, num in enumerate(lst):
        Invariant(0 <= i <= len(lst))
        Invariant(ans == sum(
            lst[k] ** 2 if k % 3 == 0 else (lst[k] ** 3 if k % 4 == 0 else lst[k])
            for k in range(i)
        ))

        if i % 3 == 0:
            ans += num ** 2
        elif i % 4 == 0:
            ans += num ** 3
        else:
            ans += num
            
    Assert(ans == sum(
        lst[k] ** 2 if k % 3 == 0 else (lst[k] ** 3 if k % 4 == 0 else lst[k])
        for k in range(len(lst))
    ))
    return ans