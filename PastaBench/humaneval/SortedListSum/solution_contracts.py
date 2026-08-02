from contracts import *


def sorted_list_sum(lst):
    """Write a function that accepts a list of strings as a parameter,
    deletes the strings that have odd lengths from it,
    and returns the resulted list with a sorted order,
    The list is always a list of strings and never an array of numbers,
    and it may contain duplicates.
    The order of the list should be ascending by length of each word, and you
    should return the list sorted by that rule.
    If two words have the same length, sort the list alphabetically.
    The function should return a list of strings in sorted order.
    You may assume that all words will have the same length.
    For example:
    assert list_sort(["aa", "a", "aaa"]) => ["aa"]
    assert list_sort(["ab", "a", "aaa", "cd"]) => ["ab", "cd"]
    """
    # The result contains only strings of even length.
    Ensures(all(len(s) % 2 == 0 for s in Result()))
    # The result's elements all originate from the input list.
    Ensures(all(s in lst for s in Result()))
    # The result contains all of the even-length strings from the input list.
    Ensures(all(s in Result() for s in lst if len(s) % 2 == 0))
    # The number of elements in the result is the number of even-length strings
    # in the input, preserving multiplicity.
    Ensures(len(Result()) == sum(1 for s in lst if len(s) % 2 == 0))
    # The result is sorted first by string length, then alphabetically.
    Ensures(all(
        len(Result()[i]) < len(Result()[i+1]) or
        (len(Result()[i]) == len(Result()[i+1]) and Result()[i] <= Result()[i+1])
        for i in range(len(Result()) - 1)
    ))

    from functools import cmp_to_key
    def cmp(s: str, t: str):
        if len(s) != len(t):
            return len(s) - len(t)
        return -1 if s < t else 1
    return sorted(list(filter(lambda s: len(s) % 2 == 0, lst)), key=cmp_to_key(cmp))