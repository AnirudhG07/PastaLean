import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Counter where
  count : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | counter (count : Int)
  deriving Repr, Inhabited

derive_storable% Counter

-- A heap free-function (`total`) called from another function / `__main__`. The call must be awaited
-- (it returns a `HeapM` action). `pastalean run` should print 2.
def Counter.new : PastaLean.HeapM Val (PastaLean.Ref Counter) :=
  ((do
      PastaLean.alloc ({ count := (0 : Int) } : Counter)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter))

def Counter.inc (self : PastaLean.Ref Counter) :=
  ((do
      self ~> count <~ (← self ~> count) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Counter.get (self : PastaLean.Ref Counter) :=
  ((do
      let __py_ret_1 := (← self ~> count)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def total :=
  ((do
      let mut a := (← Counter.new)
      let _ ← Counter.inc a
      let _ ← Counter.inc a
      let __py_ret_1 := (← Counter.get a)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

def main : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut result := (← total)
          let _ ← pyPrintIO [pyPrintArg result]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
