import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.humaneval.Encrypt

def encrypt := fun (s : String) ↦
  let d := ("abcdefghijklmnopqrstuvwxyz" : String)
  PastaLean.pyStringJoin ""
    (PastaLean.pyMap
      (fun ch ↦
        if PastaLean.pyContains d ch then
          PastaLean.pyChr
            ((PastaLean.pyOrd ch -ₚ PastaLean.pyOrd "a" +ₚ (4 : Int)) %ₚ (26 : Int) +ₚ PastaLean.pyOrd "a")
        else ch)
      s)

theorem encrypt_examples :
    encrypt "hi" = "lm" ∧ encrypt "asdfghjkl" = "ewhjklnop" ∧
      encrypt "gf" = "kj" ∧ encrypt "et" = "ix" := by
  native_decide

end PastaBench.humaneval.Encrypt
