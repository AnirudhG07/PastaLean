import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Dog where
  legs : Int
  deriving Inhabited, Repr, BEq

structure Cat where
  lives : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | dog (legs : Int)
  | cat (lives : Int)
  deriving Repr, Inhabited

derive_storable% Dog

derive_storable% Cat

-- Two independent classes in one module.
-- Exercises: the Val universe carrying MULTIPLE per-class constructors, and multiple
-- derive_storable% invocations in the one prelude.
def Dog.new := fun legs ↦
  ((do
      PastaLean.alloc ({ legs := legs } : Dog)) :
    PastaLean.HeapM Val (PastaLean.Ref Dog))

def Cat.new := fun lives ↦
  ((do
      PastaLean.alloc ({ lives := lives } : Cat)) :
    PastaLean.HeapM Val (PastaLean.Ref Cat))

def Cat.remaining (self : PastaLean.Ref Cat) :=
  ((do
      let __py_ret_1 := (← self ~> lives)
      return __py_ret_1) :
    PastaLean.HeapM Val _)
