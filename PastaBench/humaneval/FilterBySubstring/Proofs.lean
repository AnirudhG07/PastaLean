import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FilterBySubstring

/-- A boolean substring-containment test (empty substring is always contained). -/
def containsSub (sub s : String) : Bool := sub.isEmpty || (s.splitOn sub).length ≥ 2

/-- Keep the strings that contain `substring`. -/
def filterBySubstring (strings : List String) (substring : String) : List String :=
  strings.filter (fun s => containsSub substring s)

/-- Membership characterization: a string is in the result iff it was in the input
    and it contains the substring. -/
theorem filterBySubstring_mem (strings : List String) (substring s : String) :
    s ∈ filterBySubstring strings substring ↔ (s ∈ strings ∧ containsSub substring s = true) := by
  simp [filterBySubstring, List.mem_filter]

/-- Every element of the result contains the substring. -/
theorem filterBySubstring_all_contain (strings : List String) (substring : String) :
    ∀ s ∈ filterBySubstring strings substring, containsSub substring s = true := by
  intro s hs
  exact ((filterBySubstring_mem strings substring s).1 hs).2

/-- The result is a sublist (every element came from the input). -/
theorem filterBySubstring_subset (strings : List String) (substring : String) :
    ∀ s ∈ filterBySubstring strings substring, s ∈ strings := by
  intro s hs
  exact ((filterBySubstring_mem strings substring s).1 hs).1

end PastaBench.humaneval.FilterBySubstring
