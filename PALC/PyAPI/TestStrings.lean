import PastaLean
import PastaLean.PyAPI.Strings

open PastaLean

/-- info: ["alpha", "beta", "gamma"] -/
#guard_msgs in
#eval pySplit "  alpha\tbeta\n gamma  "

/-- info: ["a", "", "b", ""] -/
#guard_msgs in
#eval pySplit "a,,b," ","

/-- info: ["line1", "line2", "line3"] -/
#guard_msgs in
#eval pyStringSplitLines "line1\nline2\nline3"

/-- info: "a-b-c" -/
#guard_msgs in
#eval pyJoin "-" ["a", "b", "c"]

/-- info: "a b c" -/
#guard_msgs in
#eval pyJoin " " "abc"

/-- info: "2026/05/30" -/
#guard_msgs in
#eval pyStringJoin "/" ["2026", "05", "30"]

/-- info: "" -/
#guard_msgs in
#eval pyJoin ":" ([] : List String)

 /-- info: "baaaaa" -/
#guard_msgs in
#eval pyReplace "banana" "n" "a"

/-- info: "bbb" -/
#guard_msgs in
#eval pyReplace "aaa" "a" "b"

/-- info: "trim me" -/
#guard_msgs in
#eval pyStrip "\n\t trim me \r "

 /-- info: "hello" -/
#guard_msgs in
#eval pyStrip "xyxhelloxy" "xy"

/-- info: 2 -/
#guard_msgs in
#eval pyFind "banana" "na"

/-- info: -1 -/
#guard_msgs in
#eval pyFind "banana" "zz"

/-- info: 2 -/
#guard_msgs in
#eval pyStringIndex "banana" "na"

/-- info: true -/
#guard_msgs in
#eval pyStringStartswith "analytics" "ana"

/-- info: false -/
#guard_msgs in
#eval pyStringStartswith "analytics" "lyt"

/-- info: true -/
#guard_msgs in
#eval pyStringEndswith "analytics" "ics"

/-- info: false -/
#guard_msgs in
#eval pyStringEndswith "analytics" "ana"

/-- info: "mixed" -/
#guard_msgs in
#eval pyStringLower "MiXeD"

/-- info: "MIXED" -/
#guard_msgs in
#eval pyStringUpper "MiXeD"

/-- info: "ell" -/
#guard_msgs in
#eval pyStringSlice "hello" (some 1) (some 4)

/-- info: "he" -/
#guard_msgs in
#eval pyStringSlice "hello" (some 0) (some 2)

/-- info: "lo" -/
#guard_msgs in
#eval pyStringSlice "hello" (some 3) none

/-- info: "Hello World'S Foo" -/
#guard_msgs in
#eval pyStringTitle "hello world's foo"

/-- info: "hELLO wORLD" -/
#guard_msgs in
#eval pyStringSwapcase "Hello World"

/-- info: "Hook" -/
#guard_msgs in
#eval pyStringRemovePrefix "TestHook" "Test"

/-- info: "Test" -/
#guard_msgs in
#eval pyStringRemoveSuffix "TestHook" "Hook"

/-- info: "   42" -/
#guard_msgs in
#eval pyStringRjust "42" 5

/-- info: "42   " -/
#guard_msgs in
#eval pyStringLjust "42" 5

/-- info: "*42**" -/
#guard_msgs in
#eval pyStringCenter "42" 5 "*"

-- `str.split()` (no separator) treats Unicode blanks (NBSP U+00A0) as whitespace, like CPython.
#guard pyStringSplit (String.ofList ['a', Char.ofNat 0xa0, 'b', '\t', 'c']) == ["a", "b", "c"]

-- `split()` (no arg) collapses whitespace runs and drops empties, but `split(" ")` splits on the
-- LITERAL space, keeps empties, and does NOT split on other whitespace (`\n`, `\t`) — they differ.
#guard pyStringSplit "a  b\tc" == ["a", "b", "c"]              -- no-arg: whitespace mode
#guard pyStringSplit "a  b" " " == ["a", "", "b"]             -- explicit " ": literal, keeps empties
#guard pyStringSplit "\n\n123 456\n789\n" " " == ["\n\n123", "456\n789\n"]  -- keeps \n inside words

-- `{:02x}` / `{:X}` / `{:o}` / `{:b}` format specs convert an integer to that radix (shared by
-- `str.format` and f-strings via `pyFmtApply`).
#guard pyFmtApply "02x" "153" == "99"
#guard pyFmtApply "X" "255" == "FF"
#guard pyFmtApply "o" "8" == "10"
#guard pyFmtApply "b" "5" == "101"

-- `str.index(sub, start)` searches from `start` (Python's optional 2nd arg).
#guard pyIndex "ababab" "ab" (2 : Int) == 2
#guard pyIndex "abcabc" "bc" (2 : Int) == 4
#guard pyIndex ([1, 2, 3, 2] : List Int) (2 : Int) (2 : Int) == 3
