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

inductive Val where
  | counter (count : Int)
  deriving Repr, Inhabited

derive_storable% Counter

-- Simplest case: one Int field + a getter method.
-- Exercises: struct with a single primitive field, `Val.counter (count : Int)`,
-- derive_storable% on a trivial class, value-mode C.new (record literal) coexisting with the prelude.
def Counter.new : PastaLean.HeapM Val (PastaLean.Ref Counter) :=
  ((do
      PastaLean.alloc ({ count := (0 : Int) } : Counter)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter))

def Counter.value (self : PastaLean.Ref Counter) :=
  ((do
      let __py_ret_1 := (← self ~> count)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
