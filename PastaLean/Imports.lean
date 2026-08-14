import Mathlib.Tactic
import Std.Do
import Batteries.Data.Rat.Float
import Batteries.Data.Char.AsciiCasing
import Mathlib.Data.String.Lemmas

/-! Shared import surface for PastaLean. Files import this instead of the whole of `Mathlib`:
`Mathlib.Tactic` brings every tactic (`omega`/`grind`/`ring`/`linarith`/…) and, transitively, the
number types (`ℤ ℚ ℝ`, `Std.HashMap`, `Finset`) PastaLean and its generated code use; `Std.Do`
brings the `mvcgen` Hoare-triple framework. Add a further specific `Mathlib.X` here only if a
genuinely-needed declaration is missing. -/
