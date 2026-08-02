import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.WordsString

def words_string := fun (s : String) ↦
  let words := (PastaLean.pyStringSplit (PastaLean.pyStringReplace s "," " ") : List String)
  (List.filter (fun word => word ≠ "") (PastaLean.pyIter words)).map fun word => word

theorem words_string_nonempty :
    ∀ (s : String) (w : String), w ∈ words_string s → w ≠ "" := by
  intro s w hw
  simp only [words_string, List.mem_map, List.mem_filter] at hw
  grind only

end PastaBench.humaneval.WordsString
