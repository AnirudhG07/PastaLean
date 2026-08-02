import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ParseMusic

private def count_beats := fun (note : String) ↦
  Id.run
    (do
      if h_1 : note = "o" then return (4 : Int)
      else if h_2 : note = "o|" then return (2 : Int)
      else if h_3 : note = ".|" then return (1 : Int)
      else return (0 : Int))

def parse_music := fun (music_string : String) ↦
  Id.run
    (do
      if h_1 : music_string = "" then
        return ([] : List Int)
      else
        let _ := ()
      return PastaLean.pyList (PastaLean.pyMap count_beats (PastaLean.pyStringSplit music_string " ")))

/-- Correctness: parses the ASCII note string into per-note beat counts
    (`o`=4, `o|`=2, `.|`=1), checked on the reference test cases. -/
theorem parse_music_correct :
    parse_music "" = [] ∧
    parse_music "o o o o" = [4, 4, 4, 4] ∧
    parse_music ".| .| .| .|" = [1, 1, 1, 1] ∧
    parse_music "o| o| .| .| o o o o" = [2, 2, 1, 1, 4, 4, 4, 4] ∧
    parse_music "o| .| o| .| o o| o o|" = [2, 1, 2, 1, 4, 2, 4, 2] := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.ParseMusic
