from contracts import *
import collections
from typing import List


def maximumNumberOfStringPairs(words: List[str]) -> int:
    Ensures(
        Result()
        == sum(
            1
            for i in range(len(words))
            for j in range(i + 1, len(words))
            if words[i] == words[j][::-1]
        )
    )
    cnt = collections.Counter()
    ans = 0
    for w in words:
        ans += cnt[w[::-1]]
        cnt[w] += 1
    return ans