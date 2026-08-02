from contracts import *


def simplify(x, n):
    """Your task is to implement a function that will simplify the expression
    x * n. The function returns True if x * n evaluates to a whole number and False
    otherwise. Both x and n, are string representation of a fraction, and have the following format,
    <numerator>/<denominator> where both numerator and denominator are positive whole numbers.

    You can assume that x, and n are valid fractions, and do not have zero as denominator.

    simplify("1/5", "5/1") = True
    simplify("1/6", "2/1") = False
    simplify("7/10", "10/2") = False
    """
    Ensures(Result() == ((int(x.split("/")[0]) * int(n.split("/")[0])) %
                         (int(x.split("/")[1]) * int(n.split("/")[1])) == 0))

    x1, x2 = map(int, x.split("/"))
    n1, n2 = map(int, n.split("/"))

    # The docstring guarantees the parsed numerators and denominators are positive.
    # We formalize this precondition here, after parsing the input strings.
    Assume(x1 > 0)
    Assume(x2 > 0)
    Assume(n1 > 0)
    Assume(n2 > 0)

    # From the above, the product of denominators is positive, ensuring the
    # modulo operation is well-defined and on a non-zero divisor.
    Assert(x2 * n2 > 0)

    return (x1 * n1) % (x2 * n2) == 0