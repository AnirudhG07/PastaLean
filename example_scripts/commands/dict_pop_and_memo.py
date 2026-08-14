# `d.pop(key)` (1 arg) on a dict is the DICT pop (remove key, return value) — it shares its name with
# 1-arg `list.pop(i)`, so the receiver's dict-ness must route it. Covers a plain dict AND a Counter.
from collections import Counter
from functools import cache


def dict_pop_demo() -> int:
    d = {1: 10, 2: 20, 3: 30}
    v = d.pop(2)          # value form: removes key 2, returns 20
    d.pop(1)              # statement form: removes key 1, discards value
    total = v
    for k in d:
        total += d[k]
    return total          # 20 + 30 = 50


def counter_pop_demo(s: str) -> int:
    c = Counter(s)
    removed = 0
    for ch in "abc":
        if ch in c:
            removed += c.pop(ch)   # pop from a defaultdict-backed Counter
    return removed + len(c)


# A memoized DP whose param is reassigned to a value of the SAME type (`x = 3*x+1`) — the run-twin must
# reassign the param shadow, not emit a fresh (shadowing) `let mut x`.
@cache
def collatz_steps(x: int) -> int:
    if x == 1:
        return 0
    if x % 2 == 0:
        x //= 2
    else:
        x = 3 * x + 1
    return 1 + collatz_steps(x)


def main():
    print(dict_pop_demo())
    print(counter_pop_demo("aabbccd"))
    print(collatz_steps(6))


if __name__ == "__main__":
    main()
