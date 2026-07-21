import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Log where
  capacity : Int
  events : PastaLean.Ref (List Int)
  deriving Inhabited, Repr, BEq

inductive Val where
  | log (capacity : Int) (events : PastaLean.Ref (List Int))
  | hc_List_Int (c : List Int)
  deriving Repr, Inhabited

derive_storable% Log

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

-- IO + exceptions + heap containers: an event Log with a list field and a capacity. Two handles
-- (`log`, `mirror`) share the same object, so appends through one are seen through the other. Adding
-- past capacity raises ValueError, caught and reported as -1. Reads the capacity from input.
-- run with input "5" -> prints 3 (all three adds fit)
-- run with input "2" -> prints -1 (the third add overflows)
def Log.new := fun capacity ↦
  ((do
      PastaLean.alloc ({ capacity := capacity, events := (← PastaLean.alloc []) } : Log)) :
    PastaLean.HeapM Val (PastaLean.Ref Log))

def Log.add (self : PastaLean.Ref Log) (e) :=
  ((do
      if h_1 : PastaLean.pyLen (← PastaLean.readRef (← self ~> events)) ≥ (← self ~> capacity) then 
        throw (PastaLean.PyException.Raise "ValueError" (ToString.toString "log full"))
      else
        let _ := ()
      PastaLean.modifyRef (← self ~> events) (fun __hc_l => PastaLean.pyAppend __hc_l e)) :
    PastaLean.HeapM Val _)

def Log.size (self : PastaLean.Ref Log) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRef (← self ~> events))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def main : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut cap := PastaLean.pyInt (← PastaLean.pyInputIO "")
          let mut log := (← Log.new cap)
          let mut mirror := log
          try
            let _ ← Log.add log (10 : Int)
            let _ ← Log.add mirror (20 : Int)
            let _ ← Log.add log (30 : Int)
            let _ ← pyPrintIO [pyPrintArg (← PastaLean.PyHeapIO.captureIOErrors (Log.size mirror))]
          catch caught =>
            if (caught).OfKind == "ValueError" then 
              let _ ← pyPrintIO [pyPrintArg (-(1 : Int))]
            else
              throw caught
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
