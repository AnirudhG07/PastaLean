from contracts import *


def next_smallest(lst: list[int]):
    """
    You are given a list of integers.
    Write a function next_smallest() that returns the 2nd smallest element of the list.
    Return None if there is no such element.
    
    next_smallest([1, 2, 3, 4, 5]) == 2
    next_smallest([5, 1, 4, 3, 2]) == 2
    next_smallest([]) == None
    next_smallest([1, 1]) == None
    """
    Ensures(
        # The result is None iff there is at most one unique element.
        (len(sorted(list(set(lst)))) <= 1 and Result() is None) or
        # Otherwise, the result is the second element of the sorted unique elements.
        (len(sorted(list(set(lst)))) > 1 and Result() == sorted(list(set(lst)))[1])
    )

    if len(lst) <= 1:
        return None
    Assert(len(lst) > 1)

    sorted_list = sorted(lst)
    Assert(len(sorted_list) > 1)
    # Bridge the property from the runtime list to the input list for the Ensures clause.
    Assert(set(sorted_list) == set(lst))

    for x in sorted_list:
        if x != sorted_list[0]:
            # The first element in a sorted list that is not the minimum is, by
            # definition, the second-smallest unique element.
            return x

    # If the loop completes, it means the `if` condition was never true.
    # For a sorted list, this implies all elements are identical.
    Assert(sorted_list[0] == sorted_list[-1])
    # The function implicitly returns None here.