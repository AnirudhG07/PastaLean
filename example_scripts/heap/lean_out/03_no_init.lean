import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Config where
  width : Int := (80 : Int)
  height : Int := (24 : Int)
  deriving Inhabited, Repr, BEq

inductive Val where
  | config (width : Int) (height : Int)
  deriving Repr, Inhabited

derive_storable% Config

-- No __init__: class-level field defaults; C() builds an all-defaults instance.
-- Exercises: struct fields with defaults, the no-__init__ `C.new := default` path in heap mode.
def Config.area (self : PastaLean.Ref Config) :=
  ((do
      let __py_ret_1 := (← self ~> width) *ₚ (← self ~> height)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Config.new : PastaLean.HeapM Val (PastaLean.Ref Config) :=
  ((PastaLean.alloc (default : Config)) : PastaLean.HeapM Val (PastaLean.Ref Config))
