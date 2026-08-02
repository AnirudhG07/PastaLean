from contracts import *


def largest_smallest_integers(lst):
    '''
    Create a function that returns a tuple (a, b), where 'a' is
    the largest of negative integers, and 'b' is the smallest
    of positive integers in a list.
    If there is no negative or positive integers, return them as None.

    Examples:
    largest_smallest_integers([2, 4, 1, 3, 5, 7]) == (None, 1)
    largest_smallest_integers([]) == (None, None)
    largest_smallest_integers([0]) == (None, None)
    '''
    # Let res0 be the first element of the result tuple, and res1 be the second.

    # res0 is None if and only if there are no negative numbers in the list.
    Ensures((Result()[0] is not None) == any(x < 0 for x in lst))
    # res1 is None if and only if there are no positive numbers in the list.
    Ensures((Result()[1] is not None) == any(x > 0 for x in lst))

    # If res0 is not None, it must be a negative number from the original list.
    Ensures(Result()[0] is None or (Result()[0] < 0 and Result()[0] in lst))
    # If res1 is not None, it must be a positive number from the original list.
    Ensures(Result()[1] is None or (Result()[1] > 0 and Result()[1] in lst))

    # If res0 is not None, it must be the largest of all negative numbers in the list.
    Ensures(Result()[0] is None or all(x <= Result()[0] for x in lst if x < 0))
    # If res1 is not None, it must be the smallest of all positive numbers in the list.
    Ensures(Result()[1] is None or all(x >= Result()[1] for x in lst if x > 0))

    neg = list(filter(lambda x: x < 0, lst))
    pos = list(filter(lambda x: x > 0, lst))
    return None if neg == [] else max(neg), None if pos == [] else min(pos)