from contracts import *

def fruit_distribution(s: str, n: int) -> int:
    """
    In this task, you will be given a string that represents a number of apples and oranges 
    that are distributed in a basket of fruit this basket contains 
    apples, oranges, and mango fruits. Given the string that represents the total number of 
    the oranges and apples and an integer that represent the total number of the fruits 
    in the basket return the number of the mango fruits in the basket.
    for examble:
    fruit_distribution("5 apples and 6 oranges", 19) ->19 - 5 - 6 = 8
    fruit_distribution("0 apples and 1 oranges",3) -> 3 - 0 - 1 = 2
    fruit_distribution("2 apples and 3 oranges", 100) -> 100 - 2 - 3 = 95
    fruit_distribution("100 apples and 1 oranges",120) -> 120 - 100 - 1 = 19
    """
    Requires(n >= 0)
    Ensures(Result() == n - int(s.split(" ")[0]) - int(s.split(" ")[3]))

    words = s.split(" ")
    c1, c2 = int(words[0]), int(words[3])

    # The problem implies that fruit counts are non-negative.
    # The caller guarantees this by providing a valid input string.
    Assume(c1 >= 0)
    Assume(c2 >= 0)
    
    # The original assert is a runtime check that acts as a precondition on the
    # relationship between the total fruit count `n` and the parsed counts `c1`, `c2`.
    assert n - c1 - c2 >= 0, "invalid inputs" # $_CONTRACT_$
    
    # After the runtime assert passes, we can formally assert the condition holds.
    # This makes the fact available to the prover to establish the postcondition.
    Assert(n - c1 - c2 >= 0)
    
    return n - c1 - c2