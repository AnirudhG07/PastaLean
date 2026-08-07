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
    # The point: True exactly when len(string) is prime. Primality is spelled out as trial
    # division over EVERY candidate divisor in range(2, n) — the full definition — rather than
    # by appealing to the sqrt-bounded helper, so the contract is not a restatement of the body:
    # closing it requires the sqrt bound to be justified.
    Ensures(Result() == (len(string) > 1
                         and all(len(string) % d != 0 for d in range(2, len(string)))))

    def is_prime(a):
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))

    return is_prime(len(string))
