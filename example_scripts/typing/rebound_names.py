#!/usr/bin/env python3
"""Names Python rebinds to a DIFFERENT type.

A Lean `let mut` has one fixed type, so reassigning across types is an "invalid reassignment", and a
`let mut` cannot be shadowed either. The loop variable is therefore bound plainly and the rebind
introduces its own binding over it — which is what Python does: code before the rebind saw the old
value, code after sees the new.
"""

from typing import List


# Single loop target rebound from str to int.
def letter_sum(s: str) -> int:
    total = 0
    for ch in s:
        ch = ord(ch) - ord('a')
        total += ch
    return total


# TUPLE loop target where only the second element is rebound (a different codegen path).
def appeal(s: str) -> int:
    ans = t = 0
    pos = [-1] * 26
    for i, c in enumerate(s):
        c = ord(c) - ord('a')
        t += i - pos[c]
        ans += t
        pos[c] = i
    return ans


# The rebound name is itself reassigned afterwards, so its new binding must stay mutable.
def shifted(words: List[str]) -> int:
    total = 0
    for w in words:
        w = len(w)
        w += 1
        total += w
    return total


def main():
    print(letter_sum("abc"))
    print(appeal("abbca"))
    print(shifted(["a", "bb"]))


if __name__ == "__main__":
    main()
