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
    # The output really is a binary numeral: every character is a bit, it is non-empty,
    # and it carries no leading zero (except for the numeral "0" itself).
    Ensures(len(Result()) >= 1)
    Ensures(all(c == "0" or c == "1" for c in Result()))
    Ensures(len(Result()) == 1 or Result()[0] == "1")
    # THE POINT: decoding that binary numeral gives back the decimal digit sum of N.
    Ensures(sum([int(Result()[i]) * 2 ** (len(Result()) - 1 - i) for i in range(len(Result()))])
            == sum([int(ch) for ch in str(N)]))

    s = sum(map(lambda x: int(x), str(N)))

    Assert(s >= 0)

    return bin(s)[2:]
