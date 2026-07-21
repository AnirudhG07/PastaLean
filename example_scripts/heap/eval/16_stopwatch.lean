import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Stopwatch where
  ticks : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | stopwatch (ticks : Int)
  deriving Repr, Inhabited

derive_storable% Stopwatch

-- A stopwatch reset through an alias, then ticked once more. Exercises: reset (self.x = 0),
-- interleaved mutations, and a reset happening through a second handle. Returns 1.
def Stopwatch.new : PastaLean.HeapM Val (PastaLean.Ref Stopwatch) :=
  ((do
      PastaLean.alloc ({ ticks := (0 : Int) } : Stopwatch)) :
    PastaLean.HeapM Val (PastaLean.Ref Stopwatch))

def Stopwatch.tick (self : PastaLean.Ref Stopwatch) :=
  ((do
      self ~> ticks <~ (← self ~> ticks) +ₚ (1 : Int)) :
    PastaLean.HeapM Val Unit)

def Stopwatch.reset (self : PastaLean.Ref Stopwatch) :=
  ((do
      self ~> ticks <~ (0 : Int)) :
    PastaLean.HeapM Val Unit)

def Stopwatch.read (self : PastaLean.Ref Stopwatch) :=
  ((do
      let __py_ret_1 := (← self ~> ticks)
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut sw := (← Stopwatch.new)
      let _ ← Stopwatch.tick sw
      let _ ← Stopwatch.tick sw
      let _ ← Stopwatch.tick sw
      let mut handle := sw
      let _ ← Stopwatch.reset handle
      let _ ← Stopwatch.tick sw
      let __py_ret_1 := (← Stopwatch.read sw)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

/-- info: Except.ok 1 -/
#guard_msgs in
#eval PastaLean.eval (V := Val) demo
