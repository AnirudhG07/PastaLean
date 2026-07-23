import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

def inf {α : Type} [PastaLean.PyNonFinite α] : α :=
  PastaLean.pyNonFinite "inf"

def basic_types :=
  Id.run do
    let mut a : Int := (1 : Int)
    let mut b := (2.5 : Rat)
    let mut c : String := "hello"
    let mut d : Bool := Bool.true
    let mut e : List Int := [(1 : Int), (2 : Int)]
    let mut f : Int × String := ((1 : Int), "a")
    let __unpack_value_1 := ((3 : Int), (4.5 : Rat))
    let __unpack_pair_1 := __unpack_value_1
    let mut g := Prod.fst __unpack_pair_1
    let mut h := Prod.snd __unpack_pair_1
    let __unpack_value_2 := ((5 : Int), ("world", Bool.false))
    let __unpack_pair_2 := __unpack_value_2
    let mut m := Prod.fst __unpack_pair_2
    let mut n := Prod.fst (Prod.snd __unpack_pair_2)
    let mut p := Prod.snd (Prod.snd __unpack_pair_2)
    let mut tup1 : String × Int := ("foo", (42 : Int))
    let mut tup2 := (g, h)

attribute [simp, taste_ingr] basic_types

def basic_types'rn :=
  Id.run do
    let mut a : Int := (1 : Int)
    let mut b := (2.5 : Float)
    let mut c : String := "hello"
    let mut d : Bool := Bool.true
    let mut e : List Int := [(1 : Int), (2 : Int)]
    let mut f : Int × String := ((1 : Int), "a")
    let __unpack_value_1 := ((3 : Int), (4.5 : Float))
    let __unpack_pair_1 := __unpack_value_1
    let mut g := Prod.fst __unpack_pair_1
    let mut h := Prod.snd __unpack_pair_1
    let __unpack_value_2 := ((5 : Int), ("world", Bool.false))
    let __unpack_pair_2 := __unpack_value_2
    let mut m := Prod.fst __unpack_pair_2
    let mut n := Prod.fst (Prod.snd __unpack_pair_2)
    let mut p := Prod.snd (Prod.snd __unpack_pair_2)
    let mut tup1 : String × Int := ("foo", (42 : Int))
    let mut tup2 := (g, h)

def fstring :=
  let s1 := ("Hello" : String)
  let s2 := ("World" : String)
  let s3 := (s1 +ₚ ", " +ₚ s2 +ₚ "!" : String)
  s! "This is a string: {s3} and this is a number: {(1 : Int) +ₚ (2 : Int)}"

attribute [simp, taste_ingr] fstring

def fstring'rn :=
  let s1 := ("Hello" : String)
  let s2 := ("World" : String)
  let s3 := (s1 +ₚ ", " +ₚ s2 +ₚ "!" : String)
  s! "This is a string: {s3} and this is a number: {(1 : Int) +ₚ (2 : Int)}"

def annotated_vars :=
  let x := (10 : Int)
  let y := (20 : Int)
  x +ₚ y

attribute [simp, taste_ingr] annotated_vars

def annotated_vars'rn :=
  let x := (10 : Int)
  let y := (20 : Int)
  x +ₚ y

-- Python's numeric tower: int values coerce up to float. These guard the T1 mixed int/float codegen
-- coercions the leetcode DP corpus depends on — regressions here are otherwise only caught by rerunning
-- the corpus.
def mixed_scalar_accumulator := fun (xs : List Int) ↦
  Id.run
    (do
      -- int-seeded `ans` joins a float (`x / 2`) → must become float; the `0` seed coerces to `(0 : ℚ)`.
      let mut ans := (0 : Rat)
      for x in (PastaLean.pyIter xs)do
        ans := PastaLean.pyMax [ans, x /ₚ (2 : Int)]
      return ans)

attribute [simp, taste_ingr] mixed_scalar_accumulator

def mixed_scalar_accumulator'rn := fun (xs : List Int) ↦
  Id.run
    (do
      -- int-seeded `ans` joins a float (`x / 2`) → must become float; the `0` seed coerces to `(0 : ℚ)`.
      let mut ans := (0 : Float)
      for x in (PastaLean.pyIter xs)do
        ans := PastaLean.pyMax [ans, PastaLean.pyFloat x /ₚ (2 : Int)]
      return ans)

def int_init_float_container := fun (nums : List Int) ↦
  Id.run
    (do
      -- `dp = [0]*n` later holds floats (`/ 2`) → `List float`, with the `0` element coerced.
      let mut n : Int := PastaLean.pyLen nums
      let mut dp := (PastaLean.pyListRepeat [(0 : Rat)] n : List Rat)
      for i in (PastaLean.pyRange n (1 : Int))do
        dp := PastaLean.pySetItem dp i (dp⦋i -ₚ (1 : Int)⦌ /ₚ (2 : Int) +ₚ nums⦋i⦌ : Rat)
      return dp)

attribute [simp, taste_ingr] int_init_float_container

def int_init_float_container'rn := fun (nums : List Int) ↦
  Id.run
    (do
      -- `dp = [0]*n` later holds floats (`/ 2`) → `List float`, with the `0` element coerced.
      let mut n : Int := PastaLean.pyLen nums
      let mut dp := (PastaLean.pyListRepeat [(0 : Float)] n : List Float)
      for i in (PastaLean.pyRange n (1 : Int))do
        dp := PastaLean.pySetItem dp i (PastaLean.pyFloat dp⦋i -ₚ (1 : Int)⦌ /ₚ (2 : Int) +ₚ nums⦋i⦌ : Float)
      return dp)

def inf_dp := fun (cost : List Int) ↦
  Id.run
    (do
      -- Canonical `[inf]*n` DP: `inf` adapts to the container's float type across both twins.
      let mut n : Int := PastaLean.pyLen cost
      let mut dp := (PastaLean.pyListRepeat [inf] (n +ₚ (1 : Int)) : List Rat)
      dp := PastaLean.pySetItem dp (0 : Int) (0 : Rat)
      for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (1 : Int))do
        dp := PastaLean.pySetItem dp i (PastaLean.pyMin [dp⦋i -ₚ (1 : Int)⦌ +ₚ cost⦋i -ₚ (1 : Int)⦌, dp⦋i⦌] : Rat)
      let __py_ret_1 := dp⦋n⦌
      return __py_ret_1)

attribute [simp, taste_ingr] inf_dp

def inf_dp'rn := fun (cost : List Int) ↦
  Id.run
    (do
      -- Canonical `[inf]*n` DP: `inf` adapts to the container's float type across both twins.
      let mut n : Int := PastaLean.pyLen cost
      let mut dp := (PastaLean.pyListRepeat [inf] (n +ₚ (1 : Int)) : List Float)
      dp := PastaLean.pySetItem dp (0 : Int) (0 : Float)
      for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (1 : Int))do
        dp := PastaLean.pySetItem dp i (PastaLean.pyMin [dp⦋i -ₚ (1 : Int)⦌ +ₚ cost⦋i -ₚ (1 : Int)⦌, dp⦋i⦌] : Float)
      let __py_ret_1 := dp⦋n⦌
      return __py_ret_1)

def heterogeneous_pyany :=
  (let __PastaLean_comment_6 := ()
    let xs := ([(1 : Int), "hi", (3 : Int)] : List PyAny)
    let total := (0 : Int)
    let total := total +ₚ xs⦋(0 : Int)⦌ *ₚ (2 : Int)
    total :
    PastaLean.PyAny)

attribute [simp] heterogeneous_pyany

def heterogeneous_pyany'rn :=
  (let __PastaLean_comment_6 := ()
    let xs := ([(1 : Int), "hi", (3 : Int)] : List PyAny)
    let total := (0 : Int)
    let total := total +ₚ xs⦋(0 : Int)⦌ *ₚ (2 : Int)
    total :
    PastaLean.PyAny)