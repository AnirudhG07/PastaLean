import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Stack where
  items : PastaLean.Ref (List PastaLean.PyAny)
  deriving Inhabited, Repr, BEq

structure Stack'rn where
  items : PastaLean.Ref (List PastaLean.PyAny)
  deriving Inhabited, Repr, BEq

inductive Val where
  | stack (items : PastaLean.Ref (List PastaLean.PyAny))
  | stack'rn (items : PastaLean.Ref (List PastaLean.PyAny))
  | hc_List_Int (c : List Int)
  | hc_List_PastaLean_PyAny (c : List PastaLean.PyAny)
  deriving Repr, Inhabited

derive_storable% Stack

derive_storable% Stack'rn

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (List PastaLean.PyAny)
    where
  inject := Val.hc_List_PastaLean_PyAny
  project := fun
    | Val.hc_List_PastaLean_PyAny c => some c
    | _ => none
  project_inject := fun _ => rfl

-- A generic Stack that holds values of ANY type. Because `list[object]` can't be pinned to a single
-- concrete element type, PastaLean applies its gradual-typing fallback and boxes the element to
-- `PyAny` -- so the SAME stack holds an int, a str, and a bool at once. Each value is auto-boxed on
-- `push` and unboxed (via tag dispatch) on read. The stack lives on the heap (`Ref (List PyAny)`), so
-- it also has real reference semantics.
-- pastalean run --heap  ->  prints  3  then  42  then  hello  then  True  then  True
def Stack.new : PastaLean.HeapM Val (PastaLean.Ref Stack) :=
  ((do
      PastaLean.alloc ({ items := (← PastaLean.allocM []) } : Stack)) :
    PastaLean.HeapM Val (PastaLean.Ref Stack))

def Stack.push (self : PastaLean.Ref Stack) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Stack.get (self : PastaLean.Ref Stack) (i : Int) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRefM (← self ~> items))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.peek (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 :=
        (←
            PastaLean.readRefM
              (← self ~> items))⦋PastaLean.pyLen (← PastaLean.readRefM (← self ~> items)) -ₚ (1 : Int)⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.is_empty (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items)) == (0 : Int)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.size (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack'rn.new : PastaLean.HeapM Val (PastaLean.Ref Stack'rn) :=
  ((do
      PastaLean.alloc ({ items := (← PastaLean.allocM []) } : Stack'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Stack'rn))

def Stack'rn.push (self : PastaLean.Ref Stack'rn) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Stack'rn.get (self : PastaLean.Ref Stack'rn) (i : Int) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRefM (← self ~> items))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack'rn.peek (self : PastaLean.Ref Stack'rn) :=
  ((do
      let __py_ret_1 :=
        (←
            PastaLean.readRefM
              (← self ~> items))⦋PastaLean.pyLen (← PastaLean.readRefM (← self ~> items)) -ₚ (1 : Int)⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack'rn.is_empty (self : PastaLean.Ref Stack'rn) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items)) == (0 : Int)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack'rn.size (self : PastaLean.Ref Stack'rn) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def main : IO Unit := do
  let inputText ← IO.getStdin >>= fun h => h.readToEnd
  let inputLines := String.splitOn inputText "\n"
  let inputStream : PastaLean.ProofMode.IOStream :=
    ⟨0, fun i => PastaLean.ProofMode.IOResult.success (List.getD inputLines i "")⟩
  let initState : PastaLean.HeapIOState Val := ⟨PastaLean.emptyHeap, ⟨inputStream, []⟩⟩
  let (result, finalState) :=
    PastaLean.PyHeapProofM.runProgram (V := Val)
      (do
        let mut s := (← Stack.new)
        let _ ← Stack.push s (42 : Int)
        let _ ← Stack.push s "hello"
        let _ ← Stack.push s Bool.true
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Stack.size s)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Stack.get s (0 : Int))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Stack.get s (1 : Int))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Stack.get s (2 : Int))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Stack.peek s)]
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
          let mut s := (← Stack'rn.new)
          let _ ← Stack'rn.push s (42 : Int)
          let _ ← Stack'rn.push s "hello"
          let _ ← Stack'rn.push s Bool.true
          let _ ← pyPrintIO [pyPrintArg (← Stack'rn.size s)]
          let _ ← pyPrintIO [pyPrintArg (← Stack'rn.get s (0 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack'rn.get s (1 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack'rn.get s (2 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack'rn.peek s)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
