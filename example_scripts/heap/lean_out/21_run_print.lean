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

structure Counter'rn where
  count : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | counter (count : Int)
  | counter'rn (count : Int)
  deriving Repr, Inhabited

derive_storable% Counter

derive_storable% Counter'rn

-- A runnable heap program: build and mutate objects through an alias, then print the result.
-- `pastalean run` should print 2 (mutation through `b` seen via `a`).
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

def Counter'rn.new : PastaLean.HeapM Val (PastaLean.Ref Counter'rn) :=
  ((do
      PastaLean.alloc ({ count := (0 : Int) } : Counter'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter'rn))

def Counter'rn.inc (self : PastaLean.Ref Counter'rn) :=
  ((do
      self ~> count <~ (← self ~> count) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Counter'rn.get (self : PastaLean.Ref Counter'rn) :=
  ((do
      let __py_ret_1 := (← self ~> count)
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
        let mut a := (← Counter.new)
        let mut b := a
        let _ ← Counter.inc b
        let _ ← Counter.inc b
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Counter.get a)]
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
          let mut a := (← Counter'rn.new)
          let mut b := a
          let _ ← Counter'rn.inc b
          let _ ← Counter'rn.inc b
          let _ ← pyPrintIO [pyPrintArg (← Counter'rn.get a)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
