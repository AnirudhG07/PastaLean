import random
import functools
import collections
import string
import math
import datetime
from typing import *
from functools import *
from collections import *
from itertools import *
from heapq import *
from bisect import *
from string import *
from operator import *
from math import *
from contracts import *

def buildArray(target: List[int], n: int) -> List[str]:
    Requires(n >= 0)
    # The target array must be strictly increasing.
    Requires(all(target[i] < target[i+1] for i in range(len(target) - 1)))
    # All elements of target must be in the range [1, n].
    Requires(all(1 <= x <= n for x in target))

    # The length of the operation list follows a closed-form formula.
    Ensures(
        (len(target) == 0 and len(Result()) == 0) or
        (len(target) > 0 and len(Result()) == 2 * target[-1] - len(target))
    )

    ans = []
    cur = 1
    for x in target:
        Invariant(cur >= 1)
        # The number of 'Push' operations is always one less than the current number stream value.
        Invariant(ans.count('Push') == cur - 1)

        while cur < x:
            Invariant(cur <= x)
            # This invariant is also maintained inside the inner loop.
            Invariant(ans.count('Push') == cur - 1)
            Decreases(x - cur)

            ans.extend(['Push', 'Pop'])
            cur += 1
        
        ans.append('Push')
        cur += 1

    # After the loop, the number stream is at the value after the last target element.
    Assert(cur == (1 if len(target) == 0 else target[-1] + 1))
    
    # From the loop invariant and the final value of `cur`, we know the total push count.
    Assert(ans.count('Push') == (0 if len(target) == 0 else target[-1]))

    # Each element of target corresponds to one net 'Push', so the final stack size is len(target).
    Assert(ans.count('Push') - ans.count('Pop') == len(target))

    return ans