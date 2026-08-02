from contracts import *

def reverse_delete(s,c):
    """Task
    We are given two strings s and c, you have to deleted all the characters in s that are equal to any character in c
    then check if the result string is palindrome.
    A string is called palindrome if it reads the same backward as forward.
    You should return a tuple containing the result string and True/False for the check.
    Example
    For s = "abcde", c = "ae", the result should be ('bcd',False)
    For s = "abcdef", c = "b"  the result should be ('acdef',False)
    For s = "abcdedcba", c = "ab", the result should be ('cdedc',True)
    """
    # The length of the filtered string cannot exceed the original length.
    Ensures(len(Result()[0]) <= len(s))
    # The core property: the resulting string contains no characters from the deletion set `c`.
    Ensures(all(ch not in c for ch in Result()[0]))
    # The boolean flag must correctly report whether the filtered string is a palindrome.
    Ensures(Result()[1] == (Result()[0] == Result()[0][::-1]))

    ss = "".join(filter(lambda ch: ch not in c, s))

    # Assert the properties of the intermediate string `ss` to bridge to the postconditions.
    Assert(len(ss) <= len(s))
    Assert(all(ch not in c for ch in ss))

    return ss, ss == ss[::-1]