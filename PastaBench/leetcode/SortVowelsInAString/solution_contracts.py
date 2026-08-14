from contracts import *
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

def sortVowels(s: str) -> str:
    # THE POINT: The result has the same length, same consonants in the same places,
    # and the same multiset of vowels, but sorted.
    Ensures(len(Result()) == len(s))
    # Consonants are unchanged and remain in their original positions.
    Ensures(all(s[i] == Result()[i] for i in range(len(s)) if s[i].lower() not in 'aeiou'))
    # Vowel/consonant positions are preserved.
    Ensures(all((s[i].lower() in 'aeiou') == (Result()[i].lower() in 'aeiou') for i in range(len(s))))
    # The vowels in the result are the sorted vowels of the input.
    Ensures([c for c in Result() if c.lower() in 'aeiou'] == sorted([c for c in s if c.lower() in 'aeiou']))

    vs = [c for c in s if c.lower() in 'aeiou']
    vs.sort()
    cs = list(s)
    j = 0
    for i, c in enumerate(cs):
        # Loop counter bounds are needed for safety.
        Invariant(0 <= i <= len(s))
        Invariant(0 <= j <= len(vs))
        # j correctly counts the number of vowels seen in the prefix s[:i].
        Invariant(j == len([char for char in s[:i] if char.lower() in 'aeiou']))
        # The consonants in cs are always the same as in s.
        Invariant(all(cs[k] == s[k] for k in range(len(s)) if s[k].lower() not in 'aeiou'))
        # The vowels in the processed prefix cs[:i] are the first j sorted vowels.
        Invariant([char for char in cs[:i] if char.lower() in 'aeiou'] == vs[:j])

        if c.lower() in 'aeiou':
            # This assertion justifies the access vs[j].
            # Since s[i] is a vowel, j (the count of vowels before i) must be
            # strictly less than the total number of vowels, len(vs).
            Assert(j < len(vs))
            cs[i] = vs[j]
            j += 1
    return ''.join(cs)