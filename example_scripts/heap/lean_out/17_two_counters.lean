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
  n : Int
  deriving Inhabited, Repr, BEq

structure Counter'rn where
  n : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | counter (n : Int)
  | counter'rn (n : Int)
  deriving Repr, Inhabited

derive_storable% Counter

derive_storable% Counter'rn

-- Two SEPARATE objects (no aliasing): each `Counter()` is a distinct heap allocation, so mutating
-- one does not affect the other. Contrast with 13_aliasing. Returns 3 (a=2, b=1).
def Counter.new : PastaLean.HeapM Val (PastaLean.Ref Counter) :=
  ((do
      PastaLean.alloc ({ n := (0 : Int) } : Counter)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter))

def Counter.inc (self : PastaLean.Ref Counter) :=
  ((do
      self ~> n <~ (← self ~> n) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Counter.get (self : PastaLean.Ref Counter) :=
  ((do
      let __py_ret_1 := (← self ~> n)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Counter'rn.new : PastaLean.HeapM Val (PastaLean.Ref Counter'rn) :=
  ((do
      PastaLean.alloc ({ n := (0 : Int) } : Counter'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter'rn))

def Counter'rn.inc (self : PastaLean.Ref Counter'rn) :=
  ((do
      self ~> n <~ (← self ~> n) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Counter'rn.get (self : PastaLean.Ref Counter'rn) :=
  ((do
      let __py_ret_1 := (← self ~> n)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut a := (← Counter.new)
      let mut b := (← Counter.new)
      let _ ← Counter.inc a
      let _ ← Counter.inc a
      let _ ← Counter.inc b
      let __py_ret_1 := (← Counter.get a) +ₚ (← Counter.get b)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut a := (← Counter'rn.new)
      let mut b := (← Counter'rn.new)
      let _ ← Counter'rn.inc a
      let _ ← Counter'rn.inc a
      let _ ← Counter'rn.inc b
      let __py_ret_1 := (← Counter'rn.get a) +ₚ (← Counter'rn.get b)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)
