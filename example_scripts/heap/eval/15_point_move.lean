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

inductive Val where
  | point (x : Int) (y : Int)
  deriving Repr, Inhabited

derive_storable% Point

-- A 2D point mutated in place through an alias. Exercises: multi-arg constructor, a method mutating
-- TWO fields, a getter combining fields, and aliasing (move `q`, observe via `p`). Returns 33.
def Point.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point)) :
    PastaLean.HeapM Val (PastaLean.Ref Point))

def Point.move (self : PastaLean.Ref Point) (dx) (dy) :=
  ((do
      self ~> x <~ (← self ~> x) +ₚ dx
      self ~> y <~ (← self ~> y) +ₚ dy) :
    PastaLean.HeapM Val Unit)

def Point.manhattan (self : PastaLean.Ref Point) :=
  ((do
      let __py_ret_1 := (← self ~> x) +ₚ (← self ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut p := (← Point.new (1 : Int) (2 : Int))
      let mut q := p
      let _ ← Point.move q (10 : Int) (20 : Int)
      let __py_ret_1 := (← Point.manhattan p)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

/-- info: Except.ok 33 -/
#guard_msgs in
#eval PastaLean.eval (V := Val) demo
