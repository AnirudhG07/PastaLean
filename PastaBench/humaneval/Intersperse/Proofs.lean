import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Intersperse

def intersperse := fun (numbers : List Int) ↦ fun (delimeter : Int) ↦
  (do
    let mut res : List Int := []
    for i in (PastaLean.pyRange (PastaLean.pyLen numbers))do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) ≤ i))
      let _ := Libraries.passta.pyPassInvariant (decide (i ≤ PastaLean.pyLen numbers))
      let _ := Libraries.passta.pyPassInvariant (PastaLean.pyLen res == (2 : Int) *ₚ i)
      res := PastaLean.pyAppend res numbers⦋i⦌
      if h_1 : i ≠ PastaLean.pyLen numbers -ₚ (1 : Int) then
        res := PastaLean.pyAppend res delimeter
      else
        let _ := ()
    let _ :=
      Libraries.passta.pyPassAssert
        (PastaLean.pyLen res == PastaLean.pyMax [(0 : Int), (2 : Int) *ₚ PastaLean.pyLen numbers -ₚ (1 : Int)])
    return res : Id _)

-- Deep functional law: interspersing a delimiter among n elements yields exactly max(0, 2n-1)
-- elements. Invariant: at index i, `len res = 2i` except after the final element (2n-1), since the
-- delimiter is dropped only on the last iteration.
@[spec]
theorem intersperse_spec :
    ⦃⌜True⌝⦄ intersperse numbers delimeter ⦃⇓res =>
      ⌜PastaLean.pyLen res = PastaLean.pyMax [(0 : Int), (2 : Int) *ₚ PastaLean.pyLen numbers -ₚ (1 : Int)]⌝⦄ := by
  mvcgen [intersperse, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, res⟩ =>
      ⌜PastaLean.pyLen res =
        (if (cur.prefix.length : Int) = PastaLean.pyLen numbers ∧ 0 < PastaLean.pyLen numbers
         then 2 * (cur.prefix.length : Int) - 1
         else 2 * (cur.prefix.length : Int))⌝
  all_goals (try simp_all (config := { zetaDelta := true }) [taste_ingr])
  all_goals (try simp_all (config := { zetaDelta := true }) [taste_ingr])
  all_goals (first
    | omega
    | grind [pyLen_list_nonneg, Int.toNat_of_nonneg]
    | (have := pyLen_list_nonneg numbers; split_ifs at * <;> omega))

theorem intersperse_correct :
    ∀ (numbers : List Int), ∀ (delimeter : Int),
      let res := (intersperse numbers delimeter).run;
      PastaLean.pyLen res = PastaLean.pyMax [(0 : Int), (2 : Int) *ₚ PastaLean.pyLen numbers -ₚ (1 : Int)] := by
  intro numbers delimeter
  exact intersperse_spec True.intro

end PastaBench.humaneval.Intersperse
