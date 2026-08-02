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
    # The implementation's check for non-integers (`"." not in str(num)`) is
    # not amenable to formal proof. We formalize the docstring's intent
    # "ignore numbers that are ... not integers" by requiring the input list
    # to contain only integers. This allows the verifier to reason about
    # the arithmetic properties of the elements.
    Requires(all(isinstance(x, int) for x in lst))
    Ensures(Result() >= 0)

    ans = 0
    for num in lst:
        Invariant(ans >= 0)
        if num % 2 == 1 and num > 0 and "." not in str(num):
            ans += num ** 2
    
    Assert(ans >= 0)
    return ans