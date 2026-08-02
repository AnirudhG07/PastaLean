from contracts import *


def do_algebra(operator, operand):
    """
    Given two lists operator, and operand. The first list has basic algebra operations, and
    the second list is a list of integers. Use the two given lists to build the algebric
    expression and return the evaluation of this expression.

    The basic algebra operations:
    Addition ( + )
    Subtraction ( - )
    Multiplication ( * )
    Floor division ( // )
    Exponentiation ( ** )

    Example:
    operator['+', '*', '-']
    array = [2, 3, 4, 5]
    result = 2 + 3 * 4 - 5
    => result = 9

    Note:
        The length of operator list is equal to the length of operand list minus one.
        Operand is a list of of non-negative integers.
        Operator list has at least one operator, and operand list has at least two operands.

    """
    # Preconditions from the docstring that define the function's domain.
    Requires(len(operator) == len(operand) - 1)
    Requires(len(operator) >= 1)
    Requires(all(x >= 0 for x in operand))
    Requires(all(op in ['+', '-', '*', '//', '**'] for op in operator))

    # Safety precondition: ensure no division by zero will occur in the `eval` call.
    Requires(all(operator[i] != '//' or operand[i+1] != 0 for i in range(len(operator))))

    exp = ""
    for i in range(len(operator)):
        # Bounded-index invariant to prove memory safety of accesses inside the loop.
        Invariant(0 <= i <= len(operator))
        exp += str(operand[i]) + operator[i]
    exp += str(operand[-1])

    # An `Ensures` contract on the result is not possible because `eval` is opaque
    # to the verifier. The preconditions are the most meaningful contracts here,
    # as they guarantee the safe execution of the function.
    return eval(exp)