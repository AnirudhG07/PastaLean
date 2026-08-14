from typing import *
from contracts import *

def valid_date(date: str):
    """You have to write a function which validates a given date string and
    returns True if the date is valid otherwise False.
    The date is valid if all of the following rules are satisfied:
    1. The date string is not empty.
    2. The number of days is not less than 1 or higher than 31 days for months 1,3,5,7,8,10,12. And the number of days is not less than 1 or higher than 30 days for months 4,6,9,11. And, the number of days is not less than 1 or higher than 29 for the month 2.
    3. The months should not be less than 1 or higher than 12.
    4. The date should be in the format: mm-dd-yyyy

    for example: 
    valid_date('03-11-2000') => True

    valid_date('15-01-2012') => False

    valid_date('04-0-2040') => False

    valid_date('06-04-2020') => True

    valid_date('06/04/2020') => False
    """
    # The postcondition states that the function returns True if and only if
    # the input string satisfies the full set of validation criteria.
    # It assumes that the `and` operator in contracts short-circuits,
    # which makes the calls to `int()` safe since they are guarded by `isdigit()` checks.
    Ensures(
        Result() == (
            len(date) == 10 and
            date[2] == '-' and
            date[5] == '-' and
            date[0:2].isdigit() and
            date[3:5].isdigit() and
            date[6:].isdigit() and
            (1 <= int(date[0:2]) <= 12) and
            (1 <= int(date[3:5]) <= [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][int(date[0:2]) - 1])
        )
    )

    days = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if len(date) != 10: return False
    Assert(len(date) == 10)

    if date[2] != "-" or date[5] != "-": return False
    Assert(date[2] == "-" and date[5] == "-")

    m, d, y = date[:2], date[3:5], date[6:]
    if not m.isdigit() or not d.isdigit() or not y.isdigit(): return False
    Assert(m.isdigit() and d.isdigit() and y.isdigit())

    m, d = int(m), int(d)
    if not 1 <= m <= 12: return False
    Assert(1 <= m <= 12)

    # This assertion is crucial for proving the memory safety of the array access below.
    # It follows from `1 <= m <= 12` and `len(days) == 12`.
    Assert(0 <= m - 1 < len(days))

    if not 1 <= d <= days[m-1]: return False
    Assert(1 <= d <= days[m-1])

    return True