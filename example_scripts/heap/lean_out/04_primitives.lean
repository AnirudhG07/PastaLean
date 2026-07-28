import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Record where
  name : String := ""
  count : Int := (0 : Int)
  ratio : Rat := (0.0 : Rat)
  active : Bool := Bool.false
  deriving Inhabited, Repr, BEq

structure Record'rn where
  name : String := ""
  count : Int := (0 : Int)
  ratio : Float := (0.0 : Float)
  active : Bool := Bool.false
  deriving Inhabited, Repr, BEq

inductive Val where
  | record (name : String) (count : Int) (ratio : Rat) (active : Bool)
  | record'rn (name : String) (count : Int) (ratio : Float) (active : Bool)
  deriving Repr, Inhabited

derive_storable% Record

derive_storable% Record'rn

-- All primitive field kinds together: str, int, float, bool (via explicit annotations).
-- Exercises: every primitive Val ctor field type + the numericMode-aware float slot
-- (Float under --mode run, Rat under --mode prove) and the matching Storable instances.
def Record.total (self : PastaLean.Ref Record) :=
  ((do
      let __py_ret_1 := (← self ~> count)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Record.new : PastaLean.HeapM Val (PastaLean.Ref Record) :=
  ((PastaLean.alloc (default : Record)) : PastaLean.HeapM Val (PastaLean.Ref Record))

def Record'rn.total (self : PastaLean.Ref Record'rn) :=
  ((do
      let __py_ret_1 := (← self ~> count)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Record'rn.new : PastaLean.HeapM Val (PastaLean.Ref Record'rn) :=
  ((PastaLean.alloc (default : Record'rn)) : PastaLean.HeapM Val (PastaLean.Ref Record'rn))
