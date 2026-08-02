import Mathlib
import PastaLean.PyAPI.Operators
import PastaLean.PyAPI.PyAnyProof
import PastaLean.PyVerify.Pastafolio
import PastaLean.PyVerify.HelperLemmas

open Lean Elab Tactic
open PastaLean.Pastafolio

namespace PastaLean

/-! `taste?` — PastaLean's recipe for the Pastafolio proof-search engine. Just preferences; retune freely. -/

-- Extra lemmas for every `simp_all [taste_ingr]`. Add more with `attribute [taste_ingr] my_lemma`.
attribute [taste_ingr] mul_nonneg add_nonneg
-- Lower the Python operators to their Int/native meaning so `omega`/`grind` can see through them.
attribute [taste_ingr] PyModulo.hMod PyHAdd.hAdd PyHSub.hSub PyHMul.hMul PyFloorDiv.floorDiv
  pyMod pyFloorDiv pyBoolToInt
-- Lower `pyTruthy x` (a `while`/`if` guard) to `x ≠ 0` etc. so loop-step VCs discharge.
attribute [taste_ingr] pyTruthy PyTruthy.truthy

/-- Discovered proofs (each keyed by its tactic's byte offset), for the `py2lean` prove-and-replace
pipeline — the offset lets the splicer match each proof back to its own `taste?` token. -/
initialize tasteWinnersRef : IO.Ref (Array (Nat × String)) ← IO.mkRef #[]

/-- Simplifiers reshape the goal (lower `+ₚ`/`*ₚ`, unfold leaves, clear casts); closers must fully
discharge it — first to close wins, so order is just preference. -/
def tasteProfile : Profile where
  simplifiers := do return #[
    ← `(tactic| intros),
    ← `(tactic| simp_all (config := { zetaDelta := true }) [taste_ingr]),
    ← `(tactic| push_cast at *)
  ]
  closers := do return #[
    -- Split a boxed `PyAny` goal into one goal per relevant runtime type, then close each (no-op with no `PyAny`).
    ← `(tactic| pyany_cases <;> grind +locals),
    -- A per-goal `simp_all [taste_ingr]` closer (the simplifier runs once up front; some VCs only
    -- surface after mvcgen splits, and a lone `0 ≤ pyLen …`/operator identity closes by simp alone).
    ← `(tactic| simp_all (config := { zetaDelta := true }) [taste_ingr]),
    ← `(tactic| omega),
    ← `(tactic| grind),
    ← `(tactic| decide),
    ← `(tactic| norm_num),
    -- `if`-laden goals (e.g. floored `pyMod`/`pyFloorDiv` after unfolding) split then close arithmetically.
    ← `(tactic| split_ifs <;> omega),
    ← `(tactic| split_ifs <;> grind),
    ← `(tactic| ring),
    ← `(tactic| positivity),
    ← `(tactic| linarith),
    ← `(tactic| nlinarith),
    ← `(tactic| grind +locals +suggestions),
    ← `(tactic| aesop)
  ]
  winnersRef? := some tasteWinnersRef

syntax (name := tasteStx) "taste?" : tactic

@[tactic tasteStx]
def evalTaste : Tactic := fun stx => runPastafolio tasteProfile stx

end PastaLean
