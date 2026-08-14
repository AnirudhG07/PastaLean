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

    # `eval` is opaque, so the result cannot be pinned down in general. What CAN be defended
    # are the closed forms of the two homogeneous expressions, both of which need the string
    # built below to be the correct interleaving before they mean anything.
    Ensures(not all(op == '+' for op in operator) or Result() == sum(operand))
    Ensures(not all(op == '-' for op in operator) or Result() == operand[0] - sum(operand[1:]))
    # Subtraction is the only operation here that can leave the non-negative integers, so
    # without it the whole expression stays non-negative whatever the precedence turns out
    # to be. This is a statement about every operator in the list at once.
    Ensures(any(op == '-' for op in operator) or Result() >= 0)

    exp = ""
    for i in range(len(operator)):
        # Bounded-index invariant to prove memory safety of accesses inside the loop.
        Invariant(0 <= i)
        Invariant(i <= len(operator))
        # The point of the loop: `exp` is exactly the interleaving of the first `i` operands
        # with the first `i` operators, in order.
        Invariant(exp == "".join([str(operand[j]) + operator[j] for j in range(i)]))
        exp += str(operand[i]) + operator[i]
    exp += str(operand[-1])

    # The full infix expression, one step from the postconditions above.
    Assert(exp == "".join([str(operand[j]) + operator[j] for j in range(len(operator))])
                  + str(operand[len(operand) - 1]))
    return eval(exp)