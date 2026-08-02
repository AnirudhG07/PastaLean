from contracts import *


def prime_length(string):
    """Write a function that takes a string and returns True if the string
    length is a prime number or False otherwise
    Examples
    prime_length('Hello') == True
    prime_length('abcdcba') == True
    prime_length('kittens') == True
    prime_length('orange') == False
    """

    def is_prime(a):
        Requires(a >= 0)
        # A prime number must be greater than 1.
        Ensures(not Result() or a > 1)
        # If a number is prime, it must be 2 or be odd.
        Ensures(not Result() or a == 2 or a % 2 != 0)
        # The function should correctly identify some small composite numbers.
        Ensures(not (a == 4 or a == 6 or a == 8 or a == 9) or not Result())
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))

    return is_prime(len(string))