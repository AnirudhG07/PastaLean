import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CompareOne

def compare_one := fun (a : Option String) ↦ fun (b : Option String) ↦
  (do
    let mut num_a := PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr a) "," ".")
    let mut num_b := PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr b) "," ".")
    if h_1 : num_a = num_b then
      let _ := Libraries.passta.pyPassAssert (num_a == num_b)
      return Option.none
    else
      let _ := ()
    let _ := Libraries.passta.pyPassAssert (num_a != num_b)
    let __py_ret_1 := if num_a > num_b then a else b
    return __py_ret_1 : Id _)

/-- `compare_one` returns `None` when the two normalized numeric values are equal, otherwise
the *original* argument whose numeric value is larger. -/
theorem compare_one_correct : ∀ a b,
    (compare_one a b).run =
      (if PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr a) "," ".") =
          PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr b) "," ".")
       then Option.none
       else if PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr a) "," ".") >
               PastaLean.pyRat (PastaLean.pyStringReplace (PastaLean.pyStr b) "," ".")
            then a else b) := by
  intro a b
  simp only [compare_one, Id.run]
  split <;> rfl

end PastaBench.humaneval.CompareOne
