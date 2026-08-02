from contracts import *

def count_upper(s):
    """
    Given a string s, count the number of uppercase vowels in even indices.
    
    For example:
    count_upper('aBCdEf') returns 1
    count_upper('abcdefg') returns 0
    count_upper('dBBE') returns 0
    """
    Ensures(Result() >= 0)
    # The count of vowels at even indices cannot exceed the number of even indices,
    # which is exactly len(range(0, len(s), 2)) == (len(s)+1)//2.
    Ensures(Result() <= len(range(0, len(s), 2)))

    cnt = 0
    for i in range(0, len(s), 2):
        Invariant(0 <= i)
        Invariant(i <= len(s))
        Invariant(i % 2 == 0)
        Invariant(cnt >= 0)
        # cnt is the number of vowels found in even indices up to i-2.
        # The number of even indices examined is i/2.
        Invariant(cnt <= i // 2)
        if s[i] in "AEIOU":
            cnt += 1
    return cnt