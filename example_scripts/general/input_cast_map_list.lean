import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 200000

namespace PastaLean.User.Root

def read_int_list :=
  ((do
      let mut xs :=
        PastaLean.pyList
          (PastaLean.pyMap PastaLean.pyInt (PastaLean.pyStringSplit (← PastaLean.ProofMode.pyInputProof "")))
      return xs) :
    PastaLean.ProofMode.PyProofM _)

attribute [simp] read_int_list

def read_int_list'rn :=
  ((do
      let mut xs :=
        PastaLean.pyList (PastaLean.pyMap PastaLean.pyInt (PastaLean.pyStringSplit (← PastaLean.pyInputIO "")))
      return xs) :
    IO _)

end PastaLean.User.Root
