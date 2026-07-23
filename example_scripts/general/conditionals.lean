import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

def check_nesting := fun n ↦ fun m ↦
  if decide (n > (0 : Int)) then if decide (m ≥ (0 : Int)) then "Both positive" else "n positive, m non-positive"
  else if decide (m > (0 : Int)) then "n non-positive, m positive" else "Both non-positive"

attribute [simp, taste_ingr] check_nesting

def check_nesting'rn := fun n ↦ fun m ↦
  if decide (n > (0 : Int)) then if decide (m ≥ (0 : Int)) then "Both positive" else "n positive, m non-positive"
  else if decide (m > (0 : Int)) then "n non-positive, m positive" else "Both non-positive"

def super_nested_if := fun (a : Bool) ↦ fun (b : Bool) ↦ fun (c : Bool) ↦ fun (d : Bool) ↦
  if a then if b then if c then if d then (1 : Int) else (2 : Int) else (3 : Int) else (4 : Int) else (5 : Int)

attribute [simp, taste_ingr] super_nested_if

def super_nested_if'rn := fun (a : Bool) ↦ fun (b : Bool) ↦ fun (c : Bool) ↦ fun (d : Bool) ↦
  if a then if b then if c then if d then (1 : Int) else (2 : Int) else (3 : Int) else (4 : Int) else (5 : Int)

def complex_branching := fun x ↦
  if x == (1 : Int) then "one" else if x == (2 : Int) then "two" else if x == (3 : Int) then "three" else "other"

attribute [simp, taste_ingr] complex_branching

def complex_branching'rn := fun x ↦
  if x == (1 : Int) then "one" else if x == (2 : Int) then "two" else if x == (3 : Int) then "three" else "other"

def cond_multi := fun (x : Int) ↦
  Id.run do
    let mut x := x
    let __unpack_value_1 := ((1 : Int), ((2 : Int), (1 : Int)))
    let __unpack_pair_1 := __unpack_value_1
    let mut a := Prod.fst __unpack_pair_1
    let mut b := Prod.fst (Prod.snd __unpack_pair_1)
    let mut c := Prod.snd (Prod.snd __unpack_pair_1)
    if h_1 : a < b ∧ b > c then 
      x := x +ₚ (1 : Int)
    else
      let _ := ()

attribute [simp, taste_ingr] cond_multi

def cond_multi'rn := fun (x : Int) ↦
  Id.run do
    let mut x := x
    let __unpack_value_1 := ((1 : Int), ((2 : Int), (1 : Int)))
    let __unpack_pair_1 := __unpack_value_1
    let mut a := Prod.fst __unpack_pair_1
    let mut b := Prod.fst (Prod.snd __unpack_pair_1)
    let mut c := Prod.snd (Prod.snd __unpack_pair_1)
    if h_1 : decide (a < b) && decide (b > c) then 
      x := x +ₚ (1 : Int)
    else
      let _ := ()

def cond_none := fun (x : PyAny) ↦
  Id.run
    (do
      let mut s : String := ""
      if h_1 : PastaLean.pyIsNone x then 
        s := "x is None"
      else
        let _ := ()
      let mut y : Int := (10 : Int)
      if h_2 : !PastaLean.pyIsNone y then 
        s := s +ₚ "y is not None"
      else
        let _ := ()
      if h_3 : true ∧ true then 
        s := s +ₚ "None is None"
      else
        let _ := ()
      if h_4 : false ∨ false then 
        s := s +ₚ "None is not None"
      else
        let _ := ()
      return s)

attribute [simp, taste_ingr] cond_none

def cond_none'rn := fun (x : PyAny) ↦
  Id.run
    (do
      let mut s : String := ""
      if h_1 : PastaLean.pyIsNone x then 
        s := "x is None"
      else
        let _ := ()
      let mut y : Int := (10 : Int)
      if h_2 : !PastaLean.pyIsNone y then 
        s := s +ₚ "y is not None"
      else
        let _ := ()
      if h_3 : true && true then 
        s := s +ₚ "None is None"
      else
        let _ := ()
      if h_4 : false || false then 
        s := s +ₚ "None is not None"
      else
        let _ := ()
      return s)