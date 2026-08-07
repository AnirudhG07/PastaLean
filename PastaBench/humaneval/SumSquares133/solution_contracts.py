from contracts import *
import math


def sum_squares(lst):
    """You are given a list of numbers.
    You need to return the sum of squared numbers in the given list,
    round each element in thelist to the upper int(Ceiling) first.
    Examples:
    For lst = [1,2,3] the output should be 14
    For lst = [1,4,9] the output should be 98
    For lst = [1,3,5,7] the output should be 84
    For lst = [1.4,4.2,0] the output should be 29
    For lst = [-2.4,1,1] the output should be 6
    

    """
    import math
    # The exact fold: ceiling first, then square, then total.
    Ensures(Result() == sum(math.ceil(v) ** 2 for v in lst))
    # Every summand is a square, hence non-negative, so the total dominates each of them
    # individually and is itself non-negative (empty list => 0).
    Ensures(all(Result() >= math.ceil(v) ** 2 for v in lst))
    Ensures(Result() >= 0)
    Ensures(len(lst) > 0 or Result() == 0)

    return sum(map(lambda x: math.ceil(x) ** 2, lst))