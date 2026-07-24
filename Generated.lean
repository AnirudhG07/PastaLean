import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

/-
Algorithms taken from CPython's standard library.

    gcd                          Lib/fractions.py  (Euclid; the algorithm behind math.gcd)
    bisect_left, bisect_right    Lib/bisect.py
    mean, median                 Lib/statistics.py

Only the algorithm is kept. The `lo`/`hi` bounds arguments, the `key=` keyword and the input
validation that raises are dropped; type annotations are added.
-/
def gcd := fun (a : Int) ↦ fun (b : Int) ↦
  Id.run
    (do
      let mut a := a
      let mut b := b
      while (PastaLean.pyTruthy b) do
        let __unpack_value_1 := (b, a %ₚ b)
        let __unpack_pair_1 := __unpack_value_1
        a := Prod.fst __unpack_pair_1
        b := Prod.snd __unpack_pair_1
      return a)

attribute [simp, taste_ingr] gcd

def gcd'rn := fun (a : Int) ↦ fun (b : Int) ↦
  Id.run
    (do
      let mut a := a
      let mut b := b
      while (PastaLean.pyTruthy b) do
        let __unpack_value_1 := (b, a %ₚ b)
        let __unpack_pair_1 := __unpack_value_1
        a := Prod.fst __unpack_pair_1
        b := Prod.snd __unpack_pair_1
      return a)

def bisect_left := fun (a : List Int) ↦ fun (x : Int) ↦
  Id.run
    (do
      let mut lo : Int := (0 : Int)
      let mut hi : Int := PastaLean.pyLen a
      while (lo < hi) do
        let mut mid : Int := PastaLean.pyFloorDiv (lo +ₚ hi) (2 : Int)
        if h_1 : a⦋mid⦌ < x then 
          lo := mid +ₚ (1 : Int)
        else
          hi := mid
      return lo)

attribute [simp, taste_ingr] bisect_left

def bisect_left'rn := fun (a : List Int) ↦ fun (x : Int) ↦
  Id.run
    (do
      let mut lo : Int := (0 : Int)
      let mut hi : Int := PastaLean.pyLen a
      while (lo < hi) do
        let mut mid : Int := PastaLean.pyFloorDiv (lo +ₚ hi) (2 : Int)
        if h_1 : a⦋mid⦌ < x then 
          lo := mid +ₚ (1 : Int)
        else
          hi := mid
      return lo)

def bisect_right := fun (a : List Int) ↦ fun (x : Int) ↦
  Id.run
    (do
      let mut lo : Int := (0 : Int)
      let mut hi : Int := PastaLean.pyLen a
      while (lo < hi) do
        let mut mid : Int := PastaLean.pyFloorDiv (lo +ₚ hi) (2 : Int)
        if h_1 : x < a⦋mid⦌ then 
          hi := mid
        else
          lo := mid +ₚ (1 : Int)
      return lo)

attribute [simp, taste_ingr] bisect_right

def bisect_right'rn := fun (a : List Int) ↦ fun (x : Int) ↦
  Id.run
    (do
      let mut lo : Int := (0 : Int)
      let mut hi : Int := PastaLean.pyLen a
      while (lo < hi) do
        let mut mid : Int := PastaLean.pyFloorDiv (lo +ₚ hi) (2 : Int)
        if h_1 : x < a⦋mid⦌ then 
          hi := mid
        else
          lo := mid +ₚ (1 : Int)
      return lo)

def mean := fun (data : List Int) ↦ PastaLean.pySum data /ₚ PastaLean.pyLen data

attribute [simp, taste_ingr] mean

def mean'rn := fun (data : List Int) ↦ PastaLean.pyFloat (PastaLean.pySum data) /ₚ PastaLean.pyLen data

def median := fun (data : List Int) ↦
  (let data := PastaLean.pySort data
    let n := PastaLean.pyLen data
    if n %ₚ (2 : Int) == (1 : Int) then data⦋PastaLean.pyFloorDiv n (2 : Int)⦌
    else
      let i := PastaLean.pyFloorDiv n (2 : Int)
      (data⦋i -ₚ (1 : Int)⦌ +ₚ data⦋i⦌) /ₚ (2 : Int) :
    Rat)

attribute [simp, taste_ingr] median

def median'rn := fun (data : List Int) ↦
  (let data := PastaLean.pySort data
    let n := PastaLean.pyLen data
    if n %ₚ (2 : Int) == (1 : Int) then data⦋PastaLean.pyFloorDiv n (2 : Int)⦌
    else
      let i := PastaLean.pyFloorDiv n (2 : Int)
      PastaLean.pyFloat (data⦋i -ₚ (1 : Int)⦌ +ₚ data⦋i⦌) /ₚ (2 : Int) :
    Float)
