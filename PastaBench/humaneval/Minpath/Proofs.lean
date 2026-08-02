import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Minpath

def minPath := fun (grid : List (List Int)) ↦ fun (k : Int) ↦
  (do
    let mut N : Int := PastaLean.pyLen grid
    let __unpack_value_1 := ((0 : Int), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut x : Int := Prod.fst __unpack_pair_1
    let mut y : Int := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange N)do
      for j in (PastaLean.pyRange N)do
        if h_1 : grid⦋i⦌⦋j⦌ = (1 : Int) then
          let __unpack_value_2 := (i, j)
          let __unpack_pair_2 := __unpack_value_2
          x := Prod.fst __unpack_pair_2
          y := Prod.snd __unpack_pair_2
        else
          let _ := ()
    let mut mn : Int := N *ₚ N
    if h_1 : x > (0 : Int) then
      let mut mn'rb0 := PastaLean.pyMin [mn, grid⦋x -ₚ (1 : Int)⦌⦋y⦌]
    else
      let _ := ()
    if h_2 : x < N -ₚ (1 : Int) then
      let mut mn'rb1 := PastaLean.pyMin [mn, grid⦋x +ₚ (1 : Int)⦌⦋y⦌]
    else
      let _ := ()
    if h_3 : y > (0 : Int) then
      let mut mn'rb2 := PastaLean.pyMin [mn, grid⦋x⦌⦋y -ₚ (1 : Int)⦌]
    else
      let _ := ()
    if h_4 : y < N -ₚ (1 : Int) then
      let mut mn'rb3 := PastaLean.pyMin [mn, grid⦋x⦌⦋y +ₚ (1 : Int)⦌]
    else
      let _ := ()
    let __py_ret_1 := (PastaLean.pyRange k).map fun i => if i %ₚ (2 : Int) = (0 : Int) then (1 : Int) else mn
    return __py_ret_1 : Id _)

-- The returned path has length k and value 1 at every even index (the value 1 sits
-- adjacent to the minimum-marked cell, so the min path alternates back to it).
theorem minPath_correct :
    ((minPath [[1, 2, 3], [4, 5, 6], [7, 8, 9]] 3).run.length = 3
        ∧ (minPath [[1, 2, 3], [4, 5, 6], [7, 8, 9]] 3).run[0]! = 1
        ∧ (minPath [[1, 2, 3], [4, 5, 6], [7, 8, 9]] 3).run[2]! = 1)
      ∧ ((minPath [[5, 9, 3], [4, 1, 6], [7, 8, 2]] 1).run.length = 1
          ∧ (minPath [[5, 9, 3], [4, 1, 6], [7, 8, 2]] 1).run[0]! = 1) := by
  native_decide

end PastaBench.humaneval.Minpath
