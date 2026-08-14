from contracts import *

def triangle_area(a, b, c):
    '''
    Given the lengths of the three sides of a triangle. Return the area of
    the triangle rounded to 2 decimal points if the three sides form a valid triangle.
    Otherwise return -1
    Three sides make a valid triangle when the sum of any two sides is greater
    than the third side.
    Example:
    triangle_area(3, 4, 5) == 6.00
    triangle_area(1, 2, 10) == -1
    '''
    Requires(a > 0)
    Requires(b > 0)
    Requires(c > 0)
    # -1 comes out exactly when the triangle inequality fails.
    Ensures((a + b <= c or a + c <= b or b + c <= a) == (Result() == -1))
    Ensures(Result() == -1 or Result() >= 0)
    # THE POINT: otherwise the result satisfies Heron's relation, 16 * area^2 =
    # (a+b+c)(b+c-a)(a+c-b)(a+b-c), stated division-free and slackened by the rounding
    # to 2 decimals: |R - area| <= 0.005 gives |16R^2 - P| <= 0.16 * R + 0.0004.
    Ensures(Result() == -1 or
            abs(16 * Result() ** 2 - (a + b + c) * (b + c - a) * (a + c - b) * (a + b - c))
            <= 0.17 * Result() + 0.01)

    if a + b <= c or a + c <= b or b + c <= a:
        return -1

    # Having passed the check, we can now assert the triangle inequality holds.
    # This is the key fact that makes the subsequent math valid.
    Assert(a + b > c and a + c > b and b + c > a)

    p = (a + b + c) / 2
    # This assertion follows from the triangle inequality and ensures that the
    # term under the square root (Heron's formula) is non-negative.
    Assert(p * (p - a) * (p - b) * (p - c) >= 0)

    return round((p * (p - a) * (p - b) * (p - c)) ** 0.5, 2)
