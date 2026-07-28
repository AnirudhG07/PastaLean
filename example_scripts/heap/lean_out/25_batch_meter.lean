import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Meter where
  total : Int
  count : Int
  deriving Inhabited, Repr, BEq

structure Meter'rn where
  total : Int
  count : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | meter (total : Int) (count : Int)
  | meter'rn (total : Int) (count : Int)
  deriving Repr, Inhabited

derive_storable% Meter

derive_storable% Meter'rn

-- IO + exceptions + heap + loop: read a batch of readings and accumulate them into a shared Meter
-- object. A negative reading raises ValueError, caught per-item (reported as -1) so the loop keeps
-- going; the final total is printed at the end.
-- run with input "3\n5\n-2\n7" -> prints  -1  then  12   (5 and 7 counted, -2 rejected)
def Meter.new : PastaLean.HeapM Val (PastaLean.Ref Meter) :=
  ((do
      PastaLean.alloc ({ total := (0 : Int), count := (0 : Int) } : Meter)) :
    PastaLean.HeapM Val (PastaLean.Ref Meter))

def Meter.add (self : PastaLean.Ref Meter) (x) :=
  ((do
      if h_1 : x < (0 : Int) then 
        throw (PastaLean.PyException.Raise "ValueError" (ToString.toString "negative reading"))
      else
        let _ := ()
      self ~> total <~ (← self ~> total) +ₚ x
      self ~> count <~ (← self ~> count) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Meter.report (self : PastaLean.Ref Meter) :=
  ((do
      let __py_ret_1 := (← self ~> total)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Meter'rn.new : PastaLean.HeapM Val (PastaLean.Ref Meter'rn) :=
  ((do
      PastaLean.alloc ({ total := (0 : Int), count := (0 : Int) } : Meter'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Meter'rn))

def Meter'rn.add (self : PastaLean.Ref Meter'rn) (x) :=
  ((do
      if h_1 : x < (0 : Int) then 
        throw (PastaLean.PyException.Raise "ValueError" (ToString.toString "negative reading"))
      else
        let _ := ()
      self ~> total <~ (← self ~> total) +ₚ x
      self ~> count <~ (← self ~> count) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Meter'rn.report (self : PastaLean.Ref Meter'rn) :=
  ((do
      let __py_ret_1 := (← self ~> total)
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
        let mut m := (← Meter.new)
        let mut n := PastaLean.pyInt (← PastaLean.ProofMode.pyInputProof "")
        let mut i := (0 : Int)
        while (i < n) do
          let mut x := PastaLean.pyInt (← PastaLean.ProofMode.pyInputProof "")
          try
            let _ ← Meter.add m x
          catch caught =>
            if (caught).OfKind == "ValueError" then 
              let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (-(1 : Int))]
            else
              throw caught
          i := i +ₚ (1 : Int)
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Meter.report m)]
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
          let mut m := (← Meter'rn.new)
          let mut n := PastaLean.pyInt (← PastaLean.pyInputIO "")
          let mut i := (0 : Int)
          while (i < n) do
            let mut x := PastaLean.pyInt (← PastaLean.pyInputIO "")
            try
              let _ ← Meter'rn.add m x
            catch caught =>
              if (caught).OfKind == "ValueError" then 
                let _ ← pyPrintIO [pyPrintArg (-(1 : Int))]
              else
                throw caught
            i := i +ₚ (1 : Int)
          let _ ← pyPrintIO [pyPrintArg (← Meter'rn.report m)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
