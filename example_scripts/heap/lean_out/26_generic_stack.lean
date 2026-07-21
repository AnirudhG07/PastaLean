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

inductive Val where
  | stack (items : PastaLean.Ref (List PastaLean.PyAny))
  | hc_List_Int (c : List Int)
  | hc_List_PastaLean_PyAny (c : List PastaLean.PyAny)
  deriving Repr, Inhabited

derive_storable% Stack

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
      PastaLean.alloc ({ items := (← PastaLean.alloc []) } : Stack)) :
    PastaLean.HeapM Val (PastaLean.Ref Stack))

def Stack.push (self : PastaLean.Ref Stack) (x) :=
  ((do
      PastaLean.modifyRef (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Stack.get (self : PastaLean.Ref Stack) (i : Int) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRef (← self ~> items))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.peek (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 :=
        (← PastaLean.readRef (← self ~> items))⦋PastaLean.pyLen (← PastaLean.readRef (← self ~> items)) -ₚ (1 : Int)⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.is_empty (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRef (← self ~> items)) == (0 : Int)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Stack.size (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRef (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def main : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut s := (← Stack.new)
          let _ ← Stack.push s (42 : Int)
          let _ ← Stack.push s "hello"
          let _ ← Stack.push s Bool.true
          let _ ← pyPrintIO [pyPrintArg (← Stack.size s)]
          let _ ← pyPrintIO [pyPrintArg (← Stack.get s (0 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack.get s (1 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack.get s (2 : Int))]
          let _ ← pyPrintIO [pyPrintArg (← Stack.peek s)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
