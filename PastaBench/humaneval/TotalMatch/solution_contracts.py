from contracts import *

def total_match(lst1, lst2):
    '''
    Write a function that accepts two lists of strings and returns the list that has 
    total number of chars in the all strings of the list less than the other list.

    if the two lists have the same number of chars, return the first list.

    Examples
    total_match([], []) ➞ []
    total_match(['hi', 'admin'], ['hI', 'Hi']) ➞ ['hI', 'Hi']
    total_match(['hi', 'admin'], ['hi', 'hi', 'admin', 'project']) ➞ ['hi', 'admin']
    total_match(['hi', 'admin'], ['hI', 'hi', 'hi']) ➞ ['hI', 'hi', 'hi']
    total_match(['4'], ['1', '2', '3', '4', '5']) ➞ ['4']
    '''
    # 1. The result is one of the two inputs verbatim — nothing is built or reordered.
    Ensures(Result() == lst1 or Result() == lst2)
    # 2. It is the one with the *smaller* total character count: its own total is <= both.
    Ensures(sum([len(s) for s in Result()]) <= sum([len(s) for s in lst1]))
    Ensures(sum([len(s) for s in Result()]) <= sum([len(s) for s in lst2]))
    # 3. The stated tie-break: on a tie (indeed whenever lst1 is no longer) it is lst1.
    Ensures(sum([len(s) for s in lst1]) > sum([len(s) for s in lst2]) or Result() == lst1)

    c1, c2 =sum(map(lambda s: len(s), lst1)), sum(map(lambda s: len(s), lst2))
    
    Assert(c1 == sum([len(s) for s in lst1]))
    Assert(c2 == sum([len(s) for s in lst2]))

    return lst1 if c1 <= c2 else lst2