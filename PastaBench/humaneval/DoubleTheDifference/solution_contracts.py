from contracts import *

def double_the_difference(lst):
    '''
    Given a list of numbers, return the sum of squares of the numbers
    in the list that are odd. Ignore numbers that are negative or not integers.
    
    double_the_difference([1, 3, 2, 0]) == 1 + 9 + 0 + 0 = 10
    double_the_difference([-1, -2, 0]) == 0
    double_the_difference([9, -2]) == 81
    double_the_difference([0]) == 0  
   
    If the input list is empty, return 0.
    '''
    # No precondition: the recorded inputs deliberately mix ints, floats and negatives, so any
    # `Requires` restricting the element type would be false.
    #
    # The point: the result is the sum of squares over exactly the positive odd integers of `lst`
    # (floats and non-positives contribute nothing), hence it is a sum of odd squares.
    Ensures(Result() == sum([v * v for v in lst if v % 2 == 1 and v > 0 and "." not in str(v)]))
    # An odd square is odd, so the parity of the answer is the parity of the number of contributors.
    Ensures(Result() % 2 == len([v for v in lst if v % 2 == 1 and v > 0 and "." not in str(v)]) % 2)
    Ensures(Result() >= 0)

    ans = 0
    for num in lst:
        Invariant(ans >= 0)
        if num % 2 == 1 and num > 0 and "." not in str(num):
            ans += num ** 2

    Assert(ans >= 0)
    return ans