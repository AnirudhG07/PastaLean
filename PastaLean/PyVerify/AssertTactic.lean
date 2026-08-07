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
  -- Fail-fast portfolio: cheap decision procedures that either close instantly or bail cheaply come
  -- first; the expensive searchers (grind-family, PyAny case-split, aesop) are last resorts. Each
  -- candidate gets a FRESH heartbeat budget and first-to-close wins, so this ordering changes only
  -- how fast a goal closes, never *whether* it does — a goal only the last closer can prove is still
  -- reached. Previously `pyany_cases <;> grind +locals` was first, forcing a full `grind` on every
  -- goal (even a trivial `0 ≤ pyLen …`) before `omega` was ever tried.
  closers := do return #[
    ← `(tactic| omega),
    -- Operator identities / `0 ≤ pyLen …` often close by simp alone; some VCs only surface after an
    -- mvcgen split, so this per-goal `simp_all` closer complements the up-front simplifier.
    ← `(tactic| simp_all (config := { zetaDelta := true }) [taste_ingr]),
    ← `(tactic| norm_num),
    ← `(tactic| decide),
    -- `if`-laden goals (e.g. floored `pyMod`/`pyFloorDiv` after unfolding) split then close arithmetically.
    ← `(tactic| split_ifs <;> omega),
    ← `(tactic| ring),
    ← `(tactic| positivity),
    ← `(tactic| linarith),
    ← `(tactic| grind),
    ← `(tactic| split_ifs <;> grind),
    ← `(tactic| nlinarith),
    -- Split a boxed `PyAny` goal into one goal per relevant runtime type, then close each (no-op with no `PyAny`).
    ← `(tactic| pyany_cases <;> grind +locals),
    ← `(tactic| grind +locals +suggestions),
    ← `(tactic| aesop)
  ]
  winnersRef? := some tasteWinnersRef

syntax (name := tasteStx) "taste?" : tactic

@[tactic tasteStx]
def evalTaste : Tactic := fun stx => runPastafolio tasteProfile stx

end PastaLean
