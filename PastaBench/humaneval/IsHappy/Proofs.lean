import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.IsHappy

def is_happy := fun (s : String) ↦
  (do
    if h_1 : PastaLean.pyLen s < (3 : Int) then 
      return Bool.false
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (decide (PastaLean.pyLen s ≥ (3 : Int)))
    for i in (PastaLean.pyRange (PastaLean.pyLen s -ₚ (2 : Int)))do
      let _ := Libraries.passta.pyPassInvariant (decide (PastaLean.pyLen s ≥ (3 : Int)))
      let _ := Libraries.passta.pyPassDecreases (PastaLean.pyLen s -ₚ (2 : Int) -ₚ i)
      if h_2 : (s⦋i⦌ = s⦋i +ₚ (1 : Int)⦌ ∨ s⦋i⦌ = s⦋i +ₚ (2 : Int)⦌) ∨ s⦋i +ₚ (1 : Int)⦌ = s⦋i +ₚ (2 : Int)⦌ then 
        return Bool.false
      else
        let _ := ()
    return Bool.true : Id _)

-- Necessary condition: only a string of length ≥ 3 can be happy (the guard rejects shorter ones).
@[spec]
theorem is_happy_spec : ⦃⌜True⌝⦄ is_happy s ⦃⇓result => ⌜result = Bool.false ∨ PastaLean.pyLen s ≥ (3 : Int)⌝⦄ := by
  mvcgen [is_happy, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · Invariant.withEarlyReturn
        (onReturn := fun _ _ => ⌜PastaLean.pyLen s ≥ (3 : Int)⌝)
        (onContinue := fun _ _ => ⌜PastaLean.pyLen s ≥ (3 : Int)⌝)
  all_goals (try simp_all (config := { zetaDelta := true }) [taste_ingr])
  all_goals (first | omega | grind [pyLen_list_nonneg, Int.toNat_of_nonneg] | tauto)

theorem is_happy_correct :
    ∀ s, let result := (is_happy s).run; result = Bool.false ∨ PastaLean.pyLen s ≥ (3 : Int) := by
  intro s
  exact is_happy_spec True.intro

end PastaBench.humaneval.IsHappy
