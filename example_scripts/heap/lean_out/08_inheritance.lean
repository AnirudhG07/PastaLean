import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Base where
  x : Int
  deriving Inhabited, Repr, BEq

structure Base'rn where
  x : Int
  deriving Inhabited, Repr, BEq

structure Derived extends Base where
  y : Int
  deriving Inhabited, Repr, BEq

structure Derived'rn extends Base'rn where
  y : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | base (x : Int)
  | base'rn (x : Int)
  | derived (toBase : Base) (y : Int)
  | derived'rn (toBase : Base'rn) (y : Int)
  deriving Repr, Inhabited

derive_storable% Base

derive_storable% Base'rn

derive_storable% Derived

derive_storable% Derived'rn

-- Single inheritance (subclass extends base).
-- Exercises: `structure Derived extends Base` in the prelude AND the interaction with the generated
-- `Val` constructor / derive_storable% (whether the Val ctor's fields line up with the flattened
-- structure fields is a known sharp edge at this stage).
def Base.new := fun x ↦
  ((do
      PastaLean.alloc ({ x := x } : Base)) :
    PastaLean.HeapM Val (PastaLean.Ref Base))

def Base'rn.new := fun x ↦
  ((do
      PastaLean.alloc ({ x := x } : Base'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Base'rn))

def Derived.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Derived)) :
    PastaLean.HeapM Val (PastaLean.Ref Derived))

def Derived.total (self : PastaLean.Ref Derived) :=
  ((do
      let __py_ret_1 := (← self ~> x) +ₚ (← self ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Derived'rn.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Derived'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Derived'rn))

def Derived'rn.total (self : PastaLean.Ref Derived'rn) :=
  ((do
      let __py_ret_1 := (← self ~> x) +ₚ (← self ~> y)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
