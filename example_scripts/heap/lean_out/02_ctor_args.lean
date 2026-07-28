import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Point where
  x : Int
  y : Int
  deriving Inhabited, Repr, BEq

structure Point'rn where
  x : Int
  y : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | point (x : Int) (y : Int)
  | point'rn (x : Int) (y : Int)
  deriving Repr, Inhabited

derive_storable% Point

derive_storable% Point'rn

-- __init__ with parameters -> C.new takes arguments; fields typed from the assigned params.
-- Exercises: multi-field struct, constructor-with-args, Val ctor field ordering.
def Point.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point)) :
    PastaLean.HeapM Val (PastaLean.Ref Point))

def Point.sum (self : PastaLean.Ref Point) :=
  ((do
      let __py_ret_1 := (← self ~> x) +ₚ (← self ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Point'rn.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Point'rn))

def Point'rn.sum (self : PastaLean.Ref Point'rn) :=
  ((do
      let __py_ret_1 := (← self ~> x) +ₚ (← self ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
