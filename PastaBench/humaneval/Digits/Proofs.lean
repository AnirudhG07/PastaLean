import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Digits

-- The translated (monadic) `def digits` exactly as PastaLean emits it from the contract.
def digits := fun (n : Int) ↦
  (do
    let __unpack_value_1 := (Bool.false, (1 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut has_odd : Bool := Prod.fst __unpack_pair_1
    let mut prod : Int := Prod.snd __unpack_pair_1
    for ch in (PastaLean.pyIter (PastaLean.pyStr n))do
      if h_1 : PastaLean.pyInt ch %ₚ (2 : Int) = (1 : Int) then
        has_odd := Bool.true
        prod := prod *ₚ PastaLean.pyInt ch
      else
        let _ := ()
    let __py_ret_1 := if ¬PastaLean.pyTruthy has_odd = true then (0 : Int) else prod
    return __py_ret_1 : Id _)

-- Contract's Ensures: the result of `digits` is always 0 or odd (never a nonzero even).
-- Loop invariant: `prod` stays odd (starts at 1, only ever multiplied by odd digits).
@[spec]
theorem digits_spec :
    ⦃⌜n ≥ (0 : Int)⌝⦄ digits n ⦃⇓result =>
      ⌜result = (0 : Int) ∨ result %ₚ (2 : Int) = (1 : Int)⌝⦄ := by
  mvcgen [digits, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, has_odd, prod⟩ => ⌜prod %ₚ (2 : Int) = (1 : Int)⌝
  all_goals (try simp only [taste_ingr, PyModulo.hMod, PyHMul.hMul, pyMod, PyTruthy.truthy, pyTruthy] at *)
  all_goals grind only [= pyMul_int, Int.mul_emod]

theorem digits_correct : ∀ (n : Int), n ≥ (0 : Int) → let result := (digits n).run;
  result = (0 : Int) ∨ result %ₚ (2 : Int) = (1 : Int) := by
  intro n hpre
  exact digits_spec hpre

end PastaBench.humaneval.Digits
