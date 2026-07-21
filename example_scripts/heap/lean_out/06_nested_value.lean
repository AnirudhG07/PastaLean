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

structure Line where
  p1 : PastaLean.Ref Point
  p2 : PastaLean.Ref Point
  deriving Inhabited, Repr, BEq

inductive Val where
  | point (x : Int) (y : Int)
  | line (p1 : PastaLean.Ref Point) (p2 : PastaLean.Ref Point)
  deriving Repr, Inhabited

derive_storable% Point

derive_storable% Line

-- A class whose fields are OTHER user classes (nested value structs, HeapSL's Point/Line).
-- Exercises: prelude emission ORDER (Point must precede Line, and both precede Val, which
-- carries `line (p1 : Point) (p2 : Point)`), and derive_storable% over struct-typed fields.
def Point.new := fun x ↦ fun y ↦
  ((do
      PastaLean.alloc ({ x := x, y := y } : Point)) :
    PastaLean.HeapM Val (PastaLean.Ref Point))

def Line.new : PastaLean.Ref Point → PastaLean.Ref Point → PastaLean.HeapM Val (PastaLean.Ref Line) :=
  fun (p1 : PastaLean.Ref Point) ↦ fun (p2 : PastaLean.Ref Point) ↦
  ((do
      PastaLean.alloc ({ p1 := p1, p2 := p2 } : Line)) :
    PastaLean.HeapM Val (PastaLean.Ref Line))
