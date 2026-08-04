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
  | hc_List_Int (c : List Int)
  | hc_Float (c : Float)
  | hc_Bool (c : Bool)
  | hc_String (c : String)
  | hc_Rat (c : Rat)
  | hc_Int (c : Int)
  | hc_Ref__List_Int_ (c : Ref (List Int))
  deriving Repr, Inhabited

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

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

instance : Storable Val (Ref (List Int)) where
  inject := Val.hc_Ref__List_Int_
  project := fun
    | Val.hc_Ref__List_Int_ c => some c
    | _ => none
  project_inject := fun _ => rfl

-- Consuming a heap container RETURNED across a function boundary (--heap). A function whose return
-- type is a `list` hands back the object-ref (`Ref (List Int)`), so every consumption of the result
-- must dereference it. The driver stamps such calls `_returns_container`; codegen then treats the
-- result as a container-ref. Two consumption forms are covered:
-- - BOUND:  `ys = make_squares(4)` registers `ys` as a container, so later `len`/subscript/append/
-- iterate on `ys` dereference the object-ref.
-- - INLINE: `len(make_squares(3))` / `make_squares(3)[2]` / `for x in make_squares(3)` dereference
-- the call result directly (no binding), via the `heapContainerRef?` Call branch.
def make_squares := fun (n : Int) ↦
  ((do
      let mut out := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange n)do
        PastaLean.modifyRefM out (fun __hc_l => PastaLean.pyAppend __hc_l (i *ₚ i))
      return out) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] make_squares

def make_squares'rn := fun (n : Int) ↦
  ((do
      let mut out := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange n)do
        PastaLean.modifyRefM out (fun __hc_l => PastaLean.pyAppend __hc_l (i *ₚ i))
      return out) :
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
        let mut ys := (← make_squares (4 : Int))
        PastaLean.modifyRefM ys (fun __hc_l => PastaLean.pyAppend __hc_l (99 : Int))
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← PastaLean.readRefM ys)⦋(0 : Int)⦌]
        let _ ←
          PastaLean.ProofMode.pyPrintProof
              [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM (← make_squares (3 : Int))))]
        let _ ←
          PastaLean.ProofMode.pyPrintProof [pyPrintArg (← PastaLean.readRefM (← make_squares (3 : Int)))⦋(2 : Int)⦌]
        let mut running := (0 : Int)
        for x in (PastaLean.pyIter (← PastaLean.readRefM (← make_squares (3 : Int))))do
          running := running +ₚ x
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg running]
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
          let mut ys := (← make_squares'rn (4 : Int))
          PastaLean.modifyRefM ys (fun __hc_l => PastaLean.pyAppend __hc_l (99 : Int))
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
          let _ ← pyPrintIO [pyPrintArg (← PastaLean.readRefM ys)⦋(0 : Int)⦌]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM (← make_squares'rn (3 : Int))))]
          let _ ← pyPrintIO [pyPrintArg (← PastaLean.readRefM (← make_squares'rn (3 : Int)))⦋(2 : Int)⦌]
          let mut running := (0 : Int)
          for x in (PastaLean.pyIter (← PastaLean.readRefM (← make_squares'rn (3 : Int))))do
            running := running +ₚ x
          let _ ← pyPrintIO [pyPrintArg running]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
