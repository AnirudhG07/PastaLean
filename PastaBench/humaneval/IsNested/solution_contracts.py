from contracts import *

def is_nested(string):
    '''
    Create a function that takes a string as input which contains only square brackets.
    The function should return True if and only if there is a valid subsequence of brackets 
    where at least one bracket in the subsequence is nested.

    is_nested('[[]]') ➞ True
    is_nested('[]]]]]]][[[[[]') ➞ False
    is_nested('[][]') ➞ False
    is_nested('[]') ➞ False
    is_nested('[[][]]') ➞ True
    is_nested('[[]][[') ➞ True
    '''
    Requires(all(c == '[' or c == ']' for c in string))

    for i in range(len(string)):
        Invariant(0 <= i <= len(string))
        if string[i] == "]": continue
        
        Assert(0 <= i < len(string))
        Assert(string[i] == '[')
        cnt, max_nest = 0, 0
        for j in range(i, len(string)):
            Invariant(0 <= i < len(string))
            Invariant(i <= j <= len(string))
            Invariant(string[i] == '[')
            
            # Invariant: `max_nest` tracks the maximum nesting depth, which cannot be negative.
            Invariant(max_nest >= 0)
            
            # Invariant: `cnt` tracks the balance of brackets in the prefix `string[i:j]`.
            # Its value is bounded by the number of characters processed.
            Invariant(i - j <= cnt)
            Invariant(cnt <= j - i)

            # Invariant: `max_nest` is the maximum of `cnt` values seen so far in this scan.
            Invariant(cnt <= max_nest)
            
            Decreases(len(string) - j)

            if string[j] == "[":
                cnt += 1
            else:
                cnt -= 1
            max_nest = max(max_nest, cnt)
            
            if cnt == 0:
                # A balanced subsequence `string[i:j+1]` has been found.
                # If its maximum nesting depth was 2 or more, it's a success.
                if max_nest >= 2:
                    return True
                break
    return False