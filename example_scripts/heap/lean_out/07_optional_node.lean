import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Node where
  val : Int
  next : Option (PastaLean.Ref Node)
  deriving Inhabited, Repr, BEq

inductive Val where
  | node (val : Int) (next : Option (PastaLean.Ref Node))
  deriving Repr, Inhabited

derive_storable% Node

-- The recursive-node pattern: a field defaulting to None becomes `Option ClassName`.
-- Exercises: `Val.node (val : Int) (next : Option Node)` and derive_storable% over an Option field.
def Node.new (val : Int) (next : Option (PastaLean.Ref Node) := Option.none) :
    PastaLean.HeapM Val (PastaLean.Ref Node) :=
  ((do
      PastaLean.alloc ({ val := val, next := next } : Node)) :
    PastaLean.HeapM Val (PastaLean.Ref Node))

def Node.value (self : PastaLean.Ref Node) :=
  ((do
      let __py_ret_1 := (← self ~> val)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
