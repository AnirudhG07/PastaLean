from contracts import *


def odd_count(lst):
    """Given a list of strings, where each string consists of only digits, return a list.
    Each element i of the output should be "the number of odd elements in the
    string i of the input." where all the i's should be replaced by the number
    of odd digits in the i'th string of the input.

    >>> odd_count(['1234567'])
    ["the number of odd elements 4n the str4ng 4 of the 4nput."]
    >>> odd_count(['3',"11111111"])
    ["the number of odd elements 1n the str1ng 1 of the 1nput.",
     "the number of odd elements 8n the str8ng 8 of the 8nput."]
    """
    Requires(all(c.isdigit() for s in lst for c in s))
    Ensures(len(Result()) == len(lst))
    Ensures(
        all(
            Result()[k]
            == "the number of odd elements in the string i of the input.".replace(
                "i", str(len(list(filter(lambda ch: int(ch) % 2 == 1, lst[k]))))
            )
            for k in range(len(lst))
        )
    )

    ans, template = [], "the number of odd elements in the string i of the input."
    for s in lst:
        Invariant(len(ans) < len(lst))
        Invariant(s == lst[len(ans)])
        Invariant(
            all(
                ans[k]
                == "the number of odd elements in the string i of the input.".replace(
                    "i", str(len(list(filter(lambda ch: int(ch) % 2 == 1, lst[k]))))
                )
                for k in range(len(ans))
            )
        )

        odd_cnt = len(list(filter(lambda ch: int(ch) % 2 == 1, s)))
        Assert(0 <= odd_cnt)
        Assert(odd_cnt <= len(s))
        ans.append(template.replace("i", str(odd_cnt)))
    
    Assert(len(ans) == len(lst))
    Assert(
        all(
            ans[k]
            == "the number of odd elements in the string i of the input.".replace(
                "i", str(len(list(filter(lambda ch: int(ch) % 2 == 1, lst[k]))))
            )
            for k in range(len(lst))
        )
    )
    return ans