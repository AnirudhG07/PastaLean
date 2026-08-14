from contracts import *


def is_equal_to_sum_even(n):
    """Evaluate whether the given number n can be written as the sum of exactly 4 positive even numbers
    Example
    is_equal_to_sum_even(4) == False
    is_equal_to_sum_even(6) == False
    is_equal_to_sum_even(8) == True
    """
    # The property "can be written as the sum of 4 positive even numbers"
    # is mathematically equivalent to "is an even number greater than or equal to 8".
    # Let the four numbers be 2a, 2b, 2c, 2d where a,b,c,d >= 1.
    # The sum is 2(a+b+c+d). The sum is clearly even.
    # The minimum sum is when a=b=c=d=1, which is 2(1+1+1+1) = 8.
    # Conversely, any even number n >= 8 can be written as 2+2+2+(n-6).
    # Since n is even and >= 8, (n-6) is even and >= 2. So (n-6) is a positive even number.
    # This contract formally states the implemented property, which is the provable specification.
    Ensures(Result() == (n >= 8 and n % 2 == 0))
    return n >= 8 and n % 2 == 0