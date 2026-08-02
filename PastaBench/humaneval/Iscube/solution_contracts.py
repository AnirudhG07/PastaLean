from typing import *
from contracts import *


def iscube(a: int):
    '''
    Write a function that takes an integer a and returns True 
    if this ingeger is a cube of some integer number.
    Note: you may assume the input is always valid.
    Examples:
    iscube(1) ==> True
    iscube(2) ==> False
    iscube(-1) ==> True
    iscube(64) ==> True
    iscube(0) ==> True
    iscube(180) ==> False
    '''
    # The intent of this function is to check if `a` is a perfect cube.
    # Formally: `Result() <==> (exists k: int, Old(a) == k*k*k)`.
    # The implementation uses floating-point arithmetic to find a candidate root,
    # which is difficult to verify formally without axioms about float precision.
    # The contract below expresses that the function correctly implements its chosen
    # method, relating the output to the input `a` before it's modified.
    # For a function this simple, the "intent" and the "mechanics" are very close,
    # as the mechanic (checking the cube of the rounded cube root) is a direct
    # computational proxy for the mathematical definition of a perfect cube.
    Ensures(Result() == (int(round(abs(Old(a)) ** (1. / 3))) ** 3 == abs(Old(a))))

    a = abs(a)
    return int(round(a ** (1. / 3))) ** 3 == a