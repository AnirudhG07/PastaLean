import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

def sum_to_n := fun n ↦
  Id.run
    (do
      let mut total : Int := (0 : Int)
      let mut i : Int := (1 : Int)
      while (i ≤ n) do
        total := total +ₚ i
        i := i +ₚ (1 : Int)
      return total)

attribute [simp, taste_ingr] sum_to_n

def sum_to_n'rn := fun n ↦
  Id.run
    (do
      let mut total : Int := (0 : Int)
      let mut i : Int := (1 : Int)
      while (i ≤ n) do
        total := total +ₚ i
        i := i +ₚ (1 : Int)
      return total)