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
  items : PastaLean.Ref (List String)
  deriving Inhabited, Repr, BEq

inductive Val where
  | stack (items : PastaLean.Ref (List String))
  | hc_List_String (c : List String)
  deriving Repr, Inhabited

derive_storable% Stack

instance : Storable Val (List String) where
  inject := Val.hc_List_String
  project := fun
    | Val.hc_List_String c => some c
    | _ => none
  project_inject := fun _ => rfl

-- A generic Stack specialized to ONE element type -- like Java's Stack<String>. The element type is
-- fixed by the annotation `list[str]`, so PastaLean monomorphizes the whole class to a homogeneous
-- `Ref (List String)` (change the annotation to `list[int]` and the exact same class source becomes a
-- Stack<Integer> -> `Ref (List Int)`). Contrast 26_generic_stack.py, whose `list[object]` makes a
-- heterogeneous `Ref (List PyAny)`; here every element has the one declared type.
-- pastalean run --heap  ->  prints  2  then  world  then  hello
def Stack.new : PastaLean.HeapM Val (PastaLean.Ref Stack) :=
  ((do
      PastaLean.alloc ({ items := (← PastaLean.alloc []) } : Stack)) :
    PastaLean.HeapM Val (PastaLean.Ref Stack))

def Stack.push (self : PastaLean.Ref Stack) (x : String) :=
  ((do
      PastaLean.modifyRef (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Stack.peek (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 :=
        (← PastaLean.readRef (← self ~> items))⦋PastaLean.pyLen (← PastaLean.readRef (← self ~> items)) -ₚ (1 : Int)⦌
      return __py_ret_1) :
    PastaLean.HeapM Val String)

def Stack.get (self : PastaLean.Ref Stack) (i : Int) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRef (← self ~> items))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val String)

def Stack.size (self : PastaLean.Ref Stack) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRef (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val Int)

def main : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut s := (← Stack.new)
          let _ ← Stack.push s "hello"
          let _ ← Stack.push s "world"
          let _ ← pyPrintIO [pyPrintArg (← Stack.size s)]
          let _ ← pyPrintIO [pyPrintArg (← Stack.peek s)]
          let _ ← pyPrintIO [pyPrintArg (← Stack.get s (0 : Int))]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
