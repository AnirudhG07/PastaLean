from contracts import *


def is_palindrome(string: str) -> bool:
    """ Test if given string is a palindrome """
    Ensures(Result() == (string == string[::-1]))
    return string == string[::-1]


def make_palindrome(string: str) -> str:
    """ Find the shortest palindrome that begins with a supplied string.
    Algorithm idea is simple:
    - Find the longest postfix of supplied string that is a palindrome.
    - Append to the end of the string reverse of a string prefix that comes before the palindromic suffix.
    >>> make_palindrome('')
    ''
    >>> make_palindrome('cat')
    'catac'
    >>> make_palindrome('cata')
    'catac'
    """
    # THE POINT: the result is a palindrome that begins with `string`, and it is the
    # SHORTEST one. A palindrome of length len(string)+k starting with `string` must be
    # exactly `string + reverse(string[:k])`, so minimality is: no smaller k gives one.
    Ensures(len(Result()) >= len(string))
    Ensures(Result().startswith(string))
    Ensures(Result() == Result()[::-1])
    Ensures(Result() == string + string[:len(Result()) - len(string)][::-1])
    Ensures(all((string + string[:k][::-1]) != (string + string[:k][::-1])[::-1]
                for k in range(len(Result()) - len(string))))

    if is_palindrome(string):
        Assert(is_palindrome(string))
        return string

    Assert(not is_palindrome(string))
    for i in range(len(string)):
        Invariant(0 <= i <= len(string))
        Decreases(len(string) - i)
        if is_palindrome(string[i:]):
            # This is the first `i` for which the suffix is a palindrome.
            # The check before the loop `if is_palindrome(string)` handles the case
            # where the whole string is a palindrome (i.e., i=0).
            # Therefore, inside this branch, `i` must be greater than 0.
            Assert(i > 0)

            # Assert the postconditions just before returning to aid the prover.
            Assert((string + string[i - 1::-1]).startswith(string))
            Assert(is_palindrome(string + string[i - 1::-1]))
            return string + string[i-1::-1]

    # This path is unreachable. For any non-empty string, the last character
    # is a palindrome, so the loop is guaranteed to find an i and return.
    # Empty strings are handled by the check before the loop.
    Assert(False)