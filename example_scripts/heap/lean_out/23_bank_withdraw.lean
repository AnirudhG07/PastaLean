import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Account where
  balance : Int
  deriving Inhabited, Repr, BEq

structure Account'rn where
  balance : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | account (balance : Int)
  | account'rn (balance : Int)
  deriving Repr, Inhabited

derive_storable% Account

derive_storable% Account'rn

-- IO + exceptions + heap: a shared bank account, mutated through an alias. Reads a withdrawal amount;
-- overdrawing raises ValueError, caught and reported as -1. The mutation is done through `alias` but
-- observed through `acct` (real reference semantics).
-- run with input "40"  -> prints 60
-- run with input "150" -> prints -1
def Account.new := fun balance ↦
  ((do
      PastaLean.alloc ({ balance := balance } : Account)) :
    PastaLean.HeapM Val (PastaLean.Ref Account))

def Account.withdraw (self : PastaLean.Ref Account) (amount) :=
  ((do
      if h_1 : amount > (← self ~> balance) then 
        throw (PastaLean.PyException.Raise "ValueError" (ToString.toString "insufficient funds"))
      else
        let _ := ()
      self ~> balance <~ (← self ~> balance) -ₚ amount) :
    PastaLean.HeapM Val Unit)

def Account.get (self : PastaLean.Ref Account) :=
  ((do
      let __py_ret_1 := (← self ~> balance)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Account'rn.new := fun balance ↦
  ((do
      PastaLean.alloc ({ balance := balance } : Account'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Account'rn))

def Account'rn.withdraw (self : PastaLean.Ref Account'rn) (amount) :=
  ((do
      if h_1 : amount > (← self ~> balance) then 
        throw (PastaLean.PyException.Raise "ValueError" (ToString.toString "insufficient funds"))
      else
        let _ := ()
      self ~> balance <~ (← self ~> balance) -ₚ amount) :
    PastaLean.HeapM Val Unit)

def Account'rn.get (self : PastaLean.Ref Account'rn) :=
  ((do
      let __py_ret_1 := (← self ~> balance)
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
        let mut acct := (← Account.new (100 : Int))
        let mut «alias» := acct
        let mut n := PastaLean.pyInt (← PastaLean.ProofMode.pyInputProof "")
        try
          let _ ← Account.withdraw «alias» n
          let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← Account.get acct)]
        catch caught =>
          if (caught).OfKind == "ValueError" then 
            let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (-(1 : Int))]
          else
            throw caught
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
          let mut acct := (← Account'rn.new (100 : Int))
          let mut «alias» := acct
          let mut n := PastaLean.pyInt (← PastaLean.pyInputIO "")
          try
            let _ ← Account'rn.withdraw «alias» n
            let _ ← pyPrintIO [pyPrintArg (← PastaLean.PyHeapIO.captureIOErrors (Account'rn.get acct))]
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
