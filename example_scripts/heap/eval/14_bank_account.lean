import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure BankAccount where
  balance : Int
  deriving Inhabited, Repr, BEq

structure BankAccount'rn where
  balance : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | bankAccount (balance : Int)
  | bankAccount'rn (balance : Int)
  deriving Repr, Inhabited

derive_storable% BankAccount

derive_storable% BankAccount'rn

-- A bank account with conditional withdrawal, shared between two handles (a "joint account").
-- Exercises: constructor arg, multiple mutator methods, a conditional mutation reading self in the
-- guard, a getter, and aliasing (deposit via one handle, withdraw via the other). Returns 120.
def BankAccount.new := fun balance ↦
  ((do
      PastaLean.alloc ({ balance := balance } : BankAccount)) :
    PastaLean.HeapM Val (PastaLean.Ref BankAccount))

def BankAccount.deposit (self : PastaLean.Ref BankAccount) (amount) :=
  ((do
      self ~> balance <~ (← self ~> balance) +ₚ amount) :
    PastaLean.HeapM Val Unit)

def BankAccount.withdraw (self : PastaLean.Ref BankAccount) (amount) :=
  ((do
      if h_1 : amount ≤ (← self ~> balance) then 
        self ~> balance <~ (← self ~> balance) -ₚ amount
      else
        let _ := ()) :
    PastaLean.HeapM Val Unit)

def BankAccount.balance_of (self : PastaLean.Ref BankAccount) :=
  ((do
      let __py_ret_1 := (← self ~> balance)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def BankAccount'rn.new := fun balance ↦
  ((do
      PastaLean.alloc ({ balance := balance } : BankAccount'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref BankAccount'rn))

def BankAccount'rn.deposit (self : PastaLean.Ref BankAccount'rn) (amount) :=
  ((do
      self ~> balance <~ (← self ~> balance) +ₚ amount) :
    PastaLean.HeapM Val Unit)

def BankAccount'rn.withdraw (self : PastaLean.Ref BankAccount'rn) (amount) :=
  ((do
      if h_1 : amount ≤ (← self ~> balance) then 
        self ~> balance <~ (← self ~> balance) -ₚ amount
      else
        let _ := ()) :
    PastaLean.HeapM Val Unit)

def BankAccount'rn.balance_of (self : PastaLean.Ref BankAccount'rn) :=
  ((do
      let __py_ret_1 := (← self ~> balance)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut acc := (← BankAccount.new (100 : Int))
      let mut shared := acc
      let _ ← BankAccount.deposit acc (50 : Int)
      let _ ← BankAccount.withdraw shared (30 : Int)
      let _ ← BankAccount.withdraw shared (1000 : Int)
      let __py_ret_1 := (← BankAccount.balance_of acc)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut acc := (← BankAccount'rn.new (100 : Int))
      let mut shared := acc
      let _ ← BankAccount'rn.deposit acc (50 : Int)
      let _ ← BankAccount'rn.withdraw shared (30 : Int)
      let _ ← BankAccount'rn.withdraw shared (1000 : Int)
      let __py_ret_1 := (← BankAccount'rn.balance_of acc)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

/-- info: Except.ok 120 -/
#guard_msgs in
#eval PastaLean.eval (V := Val) demo
