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

def maskPII(s: str) -> str:
    Requires(len(s) > 0)
    # The input string is either a valid email or a valid phone number.
    # An email must contain '@' after at least one character for the name.
    # A phone number must contain at least 10 digits.
    Requires(
        (s[0].isalpha() and '@' in s and s.find('@') > 0) or
        (not s[0].isalpha() and len([c for c in s if c.isdigit()]) >= 10)
    )
    Ensures(
        (s[0].isalpha() and
            # The result has the same domain as the input, case-insensitively.
            Result().split('@')[1] == s.lower().split('@')[1] and
            # The name part of the result starts with the same letter as the input name.
            Result().split('@')[0][0] == s.lower().split('@')[0][0] and
            # The name part of the result ends with the same letter as the input name.
            Result().split('@')[0][-1] == s.lower().split('@')[0][-1] and
            # The middle of the name is masked.
            '*****' in Result().split('@')[0]
        ) or
        (not s[0].isalpha() and
            # The result ends with the last four digits of the phone number.
            Result().endswith(''.join(c for c in s if c.isdigit())[-4:]) and
            # The result only contains digits, '+', '-', or '*'.
            all(c in '0123456789*-+' for c in Result())
        )
    )

    if s[0].isalpha():
        Assert('@' in s and s.find('@') > 0)
        s = s.lower()
        return s[0] + '*****' + s[s.find('@') - 1:]
    
    Assert(not s[0].isalpha())
    # The variable `s` is rebound to its digit-only content.
    s = ''.join((c for c in s if c.isdigit()))
    Assert(len(s) >= 10)
    
    cnt = len(s) - 10
    Assert(cnt >= 0)
    
    suf = '***-***-' + s[-4:]
    return suf if cnt == 0 else f"+{'*' * cnt}-{suf}"