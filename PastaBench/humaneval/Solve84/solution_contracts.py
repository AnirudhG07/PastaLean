from contracts import *

def solve(N):
    """Given a positive integer N, return the total sum of its digits in binary.
    
    Example
        For N = 1000, the sum of digits will be 1 the output should be "1".
        For N = 150, the sum of digits will be 6 the output should be "110".
        For N = 147, the sum of digits will be 12 the output should be "1100".
    
    Variables:
        @N integer
             Constraints: 0 ≤ N ≤ 10000.
    Output:
         a string of binary number
    """
    Requires(0 <= N <= 10000)
    # The point of the function is that the integer value of the resulting binary string
    # equals the sum of the decimal digits of the input number N.
    Ensures(int(Result(), 2) == sum(map(lambda x: int(x), str(N))))

    s = sum(map(lambda x: int(x), str(N)))

    # The sum of digits is non-negative. For N <= 10000, the maximum sum is for N=9999,
    # which is 36. This gives a tight bound on the intermediate sum `s`.
    Assert(0 <= s)
    Assert(s <= 36)
    # A number is congruent to the sum of its digits modulo 9. This is a strong
    # arithmetic property connecting the input N and the intermediate sum s.
    Assert(N % 9 == s % 9)

    return bin(s)[2:]