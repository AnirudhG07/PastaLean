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
  balance : Rat
  deriving Inhabited, Repr, BEq

structure Account'rn where
  balance : Float
  deriving Inhabited, Repr, BEq

structure Savings extends Account where
  rate : Rat
  deriving Inhabited, Repr, BEq

structure Savings'rn extends Account'rn where
  rate : Float
  deriving Inhabited, Repr, BEq

inductive Val where
  | account (balance : Rat)
  | account'rn (balance : Float)
  | savings (toBase : Account) (rate : Rat)
  | savings'rn (toBase : Account'rn) (rate : Float)
  deriving Repr, Inhabited

derive_storable% Account

derive_storable% Account'rn

derive_storable% Savings

derive_storable% Savings'rn

-- Single inheritance where the base carries a mode-varying (float) field: under `--mode both` the
-- exact twin's field is ℚ and the runnable `'rn` twin's is Float, so the two twins genuinely DIFFER.
-- Regression for the `'rn` subclass extending the WRONG base (`Savings'rn extends Account` instead of
-- `Account'rn`), which mismatched Float vs ℚ at `Savings'rn.new` and broke `derive_storable%`.
def Account.new : Rat → PastaLean.HeapM Val (PastaLean.Ref Account) := fun (balance : Rat) ↦
  ((do
      PastaLean.alloc ({ balance := balance } : Account)) :
    PastaLean.HeapM Val (PastaLean.Ref Account))

def Account.deposit (self : PastaLean.Ref Account) (amount : Rat) :=
  ((do
      self ~> balance <~ (← self ~> balance) +ₚ amount) :
    PastaLean.HeapM Val Unit)

def Account'rn.new : Float → PastaLean.HeapM Val (PastaLean.Ref Account'rn) := fun (balance : Float) ↦
  ((do
      PastaLean.alloc ({ balance := balance } : Account'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Account'rn))

def Account'rn.deposit (self : PastaLean.Ref Account'rn) (amount : Float) :=
  ((do
      self ~> balance <~ (← self ~> balance) +ₚ amount) :
    PastaLean.HeapM Val Unit)

def Savings.new : Rat → Rat → PastaLean.HeapM Val (PastaLean.Ref Savings) := fun (balance : Rat) ↦ fun (rate : Rat) ↦
  ((do
      PastaLean.alloc ({ balance := balance, rate := rate } : Savings)) :
    PastaLean.HeapM Val (PastaLean.Ref Savings))

def Savings.interest (self : PastaLean.Ref Savings) :=
  ((do
      let __py_ret_1 := (← self ~> balance) *ₚ (← self ~> rate)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Savings'rn.new : Float → Float → PastaLean.HeapM Val (PastaLean.Ref Savings'rn) := fun (balance : Float) ↦
  fun (rate : Float) ↦
  ((do
      PastaLean.alloc ({ balance := balance, rate := rate } : Savings'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Savings'rn))

def Savings'rn.interest (self : PastaLean.Ref Savings'rn) :=
  ((do
      let __py_ret_1 := (← self ~> balance) *ₚ (← self ~> rate)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
