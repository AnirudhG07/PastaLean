import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

inductive Val where
  | hc_Float (c : Float)
  | hc_Bool (c : Bool)
  | hc_String (c : String)
  | hc_Rat (c : Rat)
  | hc_Int (c : Int)
  deriving Repr, Inhabited

instance : Storable Val (Float) where
  inject := Val.hc_Float
  project := fun
    | Val.hc_Float c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Bool) where
  inject := Val.hc_Bool
  project := fun
    | Val.hc_Bool c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (String) where
  inject := Val.hc_String
  project := fun
    | Val.hc_String c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Rat) where
  inject := Val.hc_Rat
  project := fun
    | Val.hc_Rat c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Int) where
  inject := Val.hc_Int
  project := fun
    | Val.hc_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

-- A closure whose ONLY heap use is a scalar CELL (`nonlocal`): no containers, no classes anywhere.
-- The captured, rebound scalar becomes a single `Ref Int`, which forces the `Val` universe to exist
-- even though nothing else touches the heap — the boundary the scalar-cell prelude fixes. Without it,
-- `HeapM Val` has an undefined `Val`. Both call forms are awaited (nested `print`, and an assignment),
-- each accumulating 1 + 2 == 3.
private def _running_total'add := fun (k : Int) ↦ fun (total : PastaLean.Ref Int) ↦
  ((do
      PastaLean.writeRefM total ((← PastaLean.readRefM total) +ₚ k)
      return (← PastaLean.readRefM total)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] _running_total'add

def running_total :=
  ((do
      let mut total := (← PastaLean.allocM (0 : Int))
      let _ ← _running_total'add (1 : Int) total
      let _ ← _running_total'add (2 : Int) total
      return (← PastaLean.readRefM total)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] running_total

private def _running_total'add'rn := fun (k : Int) ↦ fun (total : PastaLean.Ref Int) ↦
  ((do
      PastaLean.writeRefM total ((← PastaLean.readRefM total) +ₚ k)
      return (← PastaLean.readRefM total)) :
    (PastaLean.HeapM Val) _)

def running_total'rn :=
  ((do
      let mut total := (← PastaLean.allocM (0 : Int))
      let _ ← _running_total'add'rn (1 : Int) total
      let _ ← _running_total'add'rn (2 : Int) total
      return (← PastaLean.readRefM total)) :
    (PastaLean.HeapM Val) _)

def main : IO Unit := do
  let inputText ← IO.getStdin >>= fun h => h.readToEnd
  let inputLines := String.splitOn inputText "\n"
  let inputStream : PastaLean.ProofMode.IOStream :=
    ⟨0, fun i => PastaLean.ProofMode.IOResult.success (List.getD inputLines i "")⟩
  let initState : PastaLean.HeapIOState Val := ⟨PastaLean.emptyHeap, ⟨inputStream, []⟩⟩
  let (result, finalState) :=
    PastaLean.PyHeapProofM.runProgram (V := Val)
      (do
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← running_total)]
        let mut result := (← running_total)
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg result]
        pure ())
      initState
  let outputLines := finalState.io.output
  for line in outputLines do
    IO.print line
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))

def main'rn : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let _ ← pyPrintIO [pyPrintArg (← running_total'rn)]
          let mut result := (← running_total'rn)
          let _ ← pyPrintIO [pyPrintArg result]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
