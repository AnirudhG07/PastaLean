import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CheckDictCase

/-- Model the interesting (string-keyed) case: given the list of dictionary keys,
    return `True` iff the dict is non-empty and every key is lowercase, or every
    key is uppercase.  `isinstance`/`type` machinery for non-string keys is elided
    (those always yield `False`, matching the empty/mixed cases). -/
def check_dict_case := fun (keys : List String) ↦
  decide (keys ≠ []) && (keys.all pyIsLower || keys.all pyIsUpper)

theorem check_dict_case_correct :
    ∀ (keys : List String),
      check_dict_case keys = true ↔
        (keys ≠ [] ∧ (keys.all pyIsLower = true ∨ keys.all pyIsUpper = true)) := by
  intro keys
  simp only [check_dict_case, Bool.and_eq_true, Bool.or_eq_true, decide_eq_true_eq]

theorem check_dict_case_empty : check_dict_case [] = false := by
  simp [check_dict_case]

end PastaBench.humaneval.CheckDictCase
