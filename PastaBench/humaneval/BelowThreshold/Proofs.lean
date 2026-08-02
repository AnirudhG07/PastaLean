import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.BelowThreshold

def below_threshold := fun (l : List Int) ↦ fun (t : Int) ↦
  PastaLean.pyAll ((PastaLean.pyIter l).map fun x => decide (x < t))

theorem below_threshold_correct (l : List Int) (t : Int) :
    below_threshold l t = true ↔ ∀ x ∈ l, x < t := by
  have h1 : ∀ (xs : List Int), (PyIterable.toPyList xs : List Int) = xs := fun _ => rfl
  have h2 : ∀ (xs : List Bool), (PyIterable.toPyList xs : List Bool) = xs := fun _ => rfl
  simp only [below_threshold, pyAll, PyAll.pyAll, pyIter, pyBool, PyBool.pyBool, h1, h2,
    List.all_eq_true, List.mem_map, decide_eq_true_eq, forall_exists_index,
    and_imp, forall_apply_eq_imp_iff₂]

end PastaBench.humaneval.BelowThreshold
