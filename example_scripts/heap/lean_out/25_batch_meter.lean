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

inductive Val where
  | meter (total : Int) (count : Int)
  deriving Repr, Inhabited

derive_storable% Meter

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

def main : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut m := (← Meter.new)
          let mut n := PastaLean.pyInt (← PastaLean.pyInputIO "")
          for i in (PastaLean.pyRange n)do
            let mut x := PastaLean.pyInt (← PastaLean.pyInputIO "")
            try
              let _ ← Meter.add m x
            catch caught =>
              if (caught).OfKind == "ValueError" then 
                let _ ← pyPrintIO [pyPrintArg (-(1 : Int))]
              else
                throw caught
          let _ ← pyPrintIO [pyPrintArg (← Meter.report m)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
