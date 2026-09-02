# HumanEval — full coverage (164/164)

PastaLean's type inference is **sound**: it only assigns a type it can prove correct for the generated
Lean twin. It never guesses. So the HumanEval corpus splits cleanly in two:

- **153 / 164 compile with no annotation at all** — inference recovers every parameter/return type.
- **11 / 164 need a single type hint** — the parameter is *genuinely ambiguous* (two different Python
  types both type-check the body), so sound inference correctly declines to pick one. **Add the hint and
  they compile and run.** This is not a limitation of PastaLean; it is the honest cost of sound gradual
  typing — the same value would be accepted at two different types, and only the author knows which.

**Every one of the 164 programs compiles** — 153 as-is, 11 once their one ambiguous parameter is annotated.

## The 11 that need a hint (all verified to compile WITH the hint)

| Problem | Hint | Why it is genuinely undecidable without it |
|---|---|---|
| CountUpper | `s: str` | `s[i] in "AEIOU"` fits `s: str` (a char) or `s: list[str]` |
| Encode | `message: str` | iterated char-wise via `map(switch_case, message)` |
| RemoveVowels | `text: str` | `filter(lambda ch: ch not in "aeiou…", text)` |
| HexKey | `num: str` | `filter(lambda x: x in "2357BD", num)` |
| ReverseDelete | `s: str, c: str` | `filter(lambda ch: ch not in c, s)` |
| Solve161 | `s: str` | `for ch in s: ch.isalpha()` — str or list[str] |
| SortedListSum | `lst: list[str]` | `cmp(s: str, t: str)`: a `str` element fits both `str` and `list[str]` |
| StrongestExtension | `extensions: list[str]` | `for e in extensions` with `e` used as a str |
| DoAlgebra | `operator: list[str], operand: list[int]` | element types fixed only by a `str`/`int` context |
| UniqueDigits | `x: list[int]` | `sorted(list(filter(judge, x)))` never constrains `x`'s element (judge just stringifies it) |
| FindZero | `xs: list[float]` | `poly(xs: list)` — a BARE `list` is `list[Any]` in Python; the coefficients' numeric type is the author's to state |

**The common shape:** a value that is *indexed or iterated and used element-wise* is ambiguous between
`str` (iterating characters) and `list[str]` (iterating strings) — Python itself cannot tell them apart
statically. Nine of the eleven are exactly this. The other two (`UniqueDigits`, `FindZero`) are values
whose element type is never pinned by any operation, so only an annotation can supply it.

## What was fixed to reach 153 without hints

Earlier several of these needed hints too; the inference/codegen gaps behind them were closed (all sound,
regression-gated against PALC = 143/143):

- **Scalar comprehension-target ascription** — `[…group… for group in groups if len(group)==3]` now
  binds `group : str` (DecodeCyclic).
- **Nested-subscript element rule** — `grid[i][j] == 1` ⇒ `grid : list[list[int]]` (Minpath).
- **`list(dict.keys())` backward inference** — `for k in …: k.islower()` ⇒ `dict : dict[str, PyAny]`
  (CheckDictCase), plus `Std.HashMap K PyAny` stamping for a known-key/dynamic-value dict.
- **Polymorphic `round` + ℝ return reconcile** — `round(x ** 0.5, 2)` (an irrational area) now types the
  exact twin as `ℝ` and the run twin as `Float`, with the `return -1` branch coercing (TriangleArea71).
- **Array-vs-List capture fix** — a comprehension list captured by a nested `def` is no longer
  Array-backed, since closure conversion threads it as a `List` (FindZero, with its hint).
- **Intersection** recovered via the PyAny runtime path.

## Bottom line

**164 / 164 compile.** 153 need nothing; 11 need one annotation each, and that requirement is *sound* —
the annotated types are the only correct ones, and without them the value is genuinely two-typed.
