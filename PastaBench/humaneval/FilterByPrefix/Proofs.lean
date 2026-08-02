import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FilterByPrefix

/-- Keep the strings that start with `pre`. -/
def filterByPrefix (strings : List String) (pre : String) : List String :=
  strings.filter (fun s => pre.isPrefixOf s)

/-- Membership characterization: a string is in the result iff it was in the input
    and it starts with the prefix. -/
theorem filterByPrefix_mem (strings : List String) (pre : String) (s : String) :
    s ∈ filterByPrefix strings pre ↔ (s ∈ strings ∧ pre.isPrefixOf s = true) := by
  simp [filterByPrefix, List.mem_filter]

/-- Every element of the result starts with the prefix. -/
theorem filterByPrefix_all_prefixed (strings : List String) (pre : String) :
    ∀ s ∈ filterByPrefix strings pre, pre.isPrefixOf s = true := by
  intro s hs
  exact ((filterByPrefix_mem strings pre s).1 hs).2

/-- The result is a sublist (every element came from the input). -/
theorem filterByPrefix_subset (strings : List String) (pre : String) :
    ∀ s ∈ filterByPrefix strings pre, s ∈ strings := by
  intro s hs
  exact ((filterByPrefix_mem strings pre s).1 hs).1

end PastaBench.humaneval.FilterByPrefix
