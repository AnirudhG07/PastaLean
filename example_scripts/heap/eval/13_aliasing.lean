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

-- Real reference semantics: `b = a` aliases the SAME object, so a mutation through `b` is visible
-- through `a`. Under value semantics this returns 0; with --heap it returns 2.
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

def demo :=
  ((do
      let mut a := (← Counter.new)
      let mut b := a
      let _ ← Counter.inc b
      let _ ← Counter.inc b
      let __py_ret_1 := (← Counter.get a)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut a := (← Counter'rn.new)
      let mut b := a
      let _ ← Counter'rn.inc b
      let _ ← Counter'rn.inc b
      let __py_ret_1 := (← Counter'rn.get a)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

/-- info: Except.ok 2 -/
#guard_msgs in
#eval PastaLean.eval (V := Val) demo
