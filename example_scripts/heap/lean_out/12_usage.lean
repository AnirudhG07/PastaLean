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

-- A class defined AND used (instantiated + field read) in a function.
-- Exercises: the prelude coexisting with value-mode construction/attribute access at call sites
-- (real aliasing here is Stage 2; this confirms the universe does not disturb ordinary use).
def Point.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point)) :
    PastaLean.HeapM Val (PastaLean.Ref Point))

def Point'rn.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Point'rn))

def make :=
  ((do
      let mut p := (← Point.new (1 : Int) (2 : Int))
      let __py_ret_1 := (← p ~> x)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] make

def make'rn :=
  ((do
      let mut p := (← Point'rn.new (1 : Int) (2 : Int))
      let __py_ret_1 := (← p ~> x)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)
