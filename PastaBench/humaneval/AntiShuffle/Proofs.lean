import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.AntiShuffle

def anti_shuffle := fun (s : String) ↦
  let words := (PastaLean.pyStringSplit s " " : List String)
  PastaLean.pyStringJoin " "
    (PastaLean.pyMap (fun x ↦ PastaLean.pyStringJoin "" (PastaLean.pySortBy (fun ch ↦ PastaLean.pyOrd ch) false x))
      words)

/-- Correctness on the reference examples: sort each word's characters by ascii, keep word order
    and blank spaces. -/
theorem anti_shuffle_probe1 : anti_shuffle "Hi" = "Hi" := by native_decide
theorem anti_shuffle_probe2 : anti_shuffle "hello" = "ehllo" := by native_decide
theorem anti_shuffle_probe3 : anti_shuffle "number" = "bemnru" := by native_decide
theorem anti_shuffle_probe4 : anti_shuffle "Hello World!!!" = "Hello !!!Wdlor" := by native_decide

end PastaBench.humaneval.AntiShuffle
