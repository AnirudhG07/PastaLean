from contracts import *

def search(lst):
    '''
    You are given a non-empty list of positive integers. Return the greatest integer that is greater than 
    zero, and has a frequency greater than or equal to the value of the integer itself. 
    The frequency of an integer is the number of times it appears in the list.
    If no such a value exist, return -1.
    Examples:
        search([4, 1, 2, 2, 3, 1]) == 2
        search([1, 2, 2, 3, 3, 3, 4, 4, 4]) == 3
        search([5, 5, 4, 4, 4]) == -1
    '''
    Requires(len(lst) > 0)
    Requires(all(x > 0 for x in lst))

    Ensures(Result() >= -1)
    
    # If the result is positive, it must be an element of the list that satisfies
    # the frequency condition, and it must be the greatest such element.
    Ensures(
        (Result() <= -1) or (
            Result() in lst and
            lst.count(Result()) >= Result() and
            all(y <= Result() for y in lst if y > 0 and lst.count(y) >= y)
        )
    )

    # If the result is -1, it must be that no element in the list satisfies the condition.
    Ensures(
        (Result() > -1) or (
            all(lst.count(y) < y for y in lst if y > 0)
        )
    )

    count = dict()
    for num in lst:
        if num not in count:
            count[num] = 0
        count[num] += 1
    
    Assert(set(count.keys()) == set(lst))
    Assert(all(count[k] == lst.count(k) for k in count.keys()))

    ans = -1
    for num, cnt in count.items():
        Invariant(ans >= -1)
        # If ans has been updated from -1, it must itself be a number that satisfied the condition.
        Invariant((ans <= -1) or (ans in count.keys() and count[ans] >= ans))

        if cnt >= num:
            ans = max(ans, num)
            
    # After checking all numbers, ans must be greater than or equal to any valid number.
    Assert(all(k <= ans for k in count.keys() if k > 0 and count[k] >= k))

    return ans