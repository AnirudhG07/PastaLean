import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.IsBored

def is_bored := fun (S : String) ↦
  let sentences :=
    PastaLean.pyMap (fun x ↦ PastaLean.pyStringStrip x)
      (PastaLean.pyStringSplit (PastaLean.pyStringReplace (PastaLean.pyStringReplace S "?" ".") "!" ".") ".")
  PastaLean.pyLen
    ((List.filter (fun s => PastaLean.pyTruthy (PastaLean.pyStringStartswith s "I ")) (PastaLean.pyIter sentences)).map
      fun s => s)

/-- The boredom count is nonnegative and never exceeds the number of sentences the text
    is split into. -/
theorem is_bored_bounds (S : String) :
    0 ≤ is_bored S ∧
      is_bored S ≤ PastaLean.pyLen
        (PastaLean.pyStringSplit (PastaLean.pyStringReplace (PastaLean.pyStringReplace S "?" ".") "!" ".") ".") := by
  simp only [is_bored, pyLen, PyLen.pyLen, pyMap, pyIter, PyIterable.toPyList, List.map_id_fun,
    id_eq, List.map_id']
  refine ⟨by positivity, ?_⟩
  have hle := List.length_filter_le
    (fun s => PastaLean.pyTruthy (PastaLean.pyStringStartswith s "I "))
    (List.map (fun x => PastaLean.pyStringStrip x)
      (PastaLean.pyStringSplit (PastaLean.pyStringReplace (PastaLean.pyStringReplace S "?" ".") "!" ".") "."))
  rw [List.length_map] at hle
  exact_mod_cast hle

end PastaBench.humaneval.IsBored
