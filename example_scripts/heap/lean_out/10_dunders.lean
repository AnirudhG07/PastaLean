import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Vec where
  x : Int
  y : Int
  deriving Inhabited, Repr

inductive Val where
  | vec (x : Int) (y : Int)
  deriving Repr, Inhabited

derive_storable% Vec

-- Operator/print dunders become typeclass instances alongside the prelude.
-- Exercises: __add__ -> PyHAdd, __eq__ -> BEq (so the struct does NOT derive BEq), __str__ ->
-- PyPrintable, all referencing the prelude-emitted structure.
def Vec.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Vec)) :
    PastaLean.HeapM Val (PastaLean.Ref Vec))

def Vec.__add__ (self : PastaLean.Ref Vec) (other : PastaLean.Ref Vec) :=
  ((do
      let __py_ret_1 := (← Vec.new ((← self ~> x) +ₚ (← other ~> x)) ((← self ~> y) +ₚ (← other ~> y)))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Vec.__eq__ (self : PastaLean.Ref Vec) (other : PastaLean.Ref Vec) :=
  ((do
      let __py_ret_1 := (← self ~> x) == (← other ~> x) && (← self ~> y) == (← other ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Vec.__str__ (self : PastaLean.Ref Vec) :=
  ((do
      return "vec") :
    PastaLean.HeapM Val _)
