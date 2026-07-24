from contracts import *

def divisorGame(n: int) -> bool:
    Ensures(Result() == (n % 2 == 0))
    return n % 2 == 0