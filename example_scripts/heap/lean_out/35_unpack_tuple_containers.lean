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

-- Consuming a RETURNED tuple-of-containers, unpacked at module scope (--heap). A function returning
-- `tuple[list, list]` hands back a pair of object-refs; the main-guard unpack `xs, ys = split(...)`
-- must register BOTH targets as container-refs (`_unpack_container_mask`, stamped only once the guard
-- body is inferred with the full interprocedural `sigs`) so every downstream use dereferences.
-- Exercises three consumption families the earlier heap examples did not:
-- - print(container-ref) and print((xs, ys)) — a print / tuple-literal derefs each container element.
-- - builtins consuming an iterable BY VALUE — sum/min/max/sorted deref the ref to its contents.
-- - subscript / len on the unpacked refs.
def split_parity := fun (n : Int) ↦
  ((do
      let mut evens := (← PastaLean.allocM [])
      let mut odds := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange n)do
        if h_1 : i %ₚ (2 : Int) = (0 : Int) then 
          PastaLean.modifyRefM evens (fun __hc_l => PastaLean.pyAppend __hc_l i)
        else
          PastaLean.modifyRefM odds (fun __hc_l => PastaLean.pyAppend __hc_l i)
      let __py_ret_1 := (evens, odds)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] split_parity

def split_parity'rn := fun (n : Int) ↦
  ((do
      let mut evens := (← PastaLean.allocM [])
      let mut odds := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange n)do
        if h_1 : i %ₚ (2 : Int) == (0 : Int) then 
          PastaLean.modifyRefM evens (fun __hc_l => PastaLean.pyAppend __hc_l i)
        else
          PastaLean.modifyRefM odds (fun __hc_l => PastaLean.pyAppend __hc_l i)
      let __py_ret_1 := (evens, odds)
      return __py_ret_1) :
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
        let __unpack_value_1 := (← split_parity (6 : Int))
        let __unpack_pair_1 := __unpack_value_1
        let mut xs := Prod.fst __unpack_pair_1
        let mut ys := Prod.snd __unpack_pair_1
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← PastaLean.readRefM xs)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg ((← PastaLean.readRefM xs), (← PastaLean.readRefM ys))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM xs))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← PastaLean.readRefM xs)⦋(2 : Int)⦌]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pySum (← PastaLean.readRefM xs))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyMin (← PastaLean.readRefM ys))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyMax (← PastaLean.readRefM ys))]
        let _ ←
          PastaLean.ProofMode.pyPrintProof
              [pyPrintArg (PastaLean.pySortBy (fun x => x) Bool.true (← PastaLean.readRefM xs))]
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
          let __unpack_value_1 := (← split_parity'rn (6 : Int))
          let __unpack_pair_1 := __unpack_value_1
          let mut xs := Prod.fst __unpack_pair_1
          let mut ys := Prod.snd __unpack_pair_1
          let _ ← pyPrintIO [pyPrintArg (← PastaLean.readRefM xs)]
          let _ ← pyPrintIO [pyPrintArg ((← PastaLean.readRefM xs), (← PastaLean.readRefM ys))]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM xs))]
          let _ ← pyPrintIO [pyPrintArg (← PastaLean.readRefM xs)⦋(2 : Int)⦌]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pySum (← PastaLean.readRefM xs))]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyMin (← PastaLean.readRefM ys))]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyMax (← PastaLean.readRefM ys))]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pySortBy (fun x => x) Bool.true (← PastaLean.readRefM xs))]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
