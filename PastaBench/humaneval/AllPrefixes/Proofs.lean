import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.AllPrefixes

def all_prefixes := fun (string : String) ↦
  (PastaLean.pyRange (PastaLean.pyLen string)).map fun i =>
    PastaLean.pySlice string none (some (i +ₚ (1 : Int))) none

theorem all_prefixes_length (string : String) :
    PastaLean.pyLen (all_prefixes string) = PastaLean.pyLen string := by
  simp only [all_prefixes, pyLen, PyLen.pyLen, List.length_map]
  rw [pyRange_eq_ofNat]
  simp [Int.toNat_natCast]

end PastaBench.humaneval.AllPrefixes
