import Libraries

open Libraries.collections

/-!
`Counter`/`defaultdict` (`PyDefaultDict`) runtime checks. The key one: Python's `Counter.__eq__`
treats a `0`-count (from `cnt[x] -= 1`) as an ABSENT key, so a sliding-window anagram compare
(`Counter(window) == Counter(pattern)`) still matches after a decrement zeroes a key.
-/

-- `Counter({'a':1, 'b':0}) == Counter({'a':1})` — the zero-count key is ignored (both orientations).
#guard ((((PyDefaultDict.empty (0 : Int)).insert "a" 1).insert "b" 0) ==
         ((PyDefaultDict.empty (0 : Int)).insert "a" 1)) == true
#guard (((PyDefaultDict.empty (0 : Int)).insert "a" 1) ==
         (((PyDefaultDict.empty (0 : Int)).insert "a" 1).insert "b" 0)) == true

-- A genuine count difference is NOT equal.
#guard ((((PyDefaultDict.empty (0 : Int)).insert "a" 1).insert "b" 1) ==
         ((PyDefaultDict.empty (0 : Int)).insert "a" 1)) == false
