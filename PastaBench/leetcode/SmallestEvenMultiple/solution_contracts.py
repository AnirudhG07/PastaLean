from contracts import *

def smallestEvenMultiple(n: int) -> int:
    Ensures((n % 2 == 0 and Result() == n)
            or (n % 2 != 0 and Result() == 2 * n))
    return n if n % 2 == 0 else n * 2