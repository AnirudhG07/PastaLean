import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

-- !/usr/bin/env python3
/-
Containers built in one scope and captured by a nested `def`.

Lambda lifting turns each capture into a real parameter, and Lean will not infer a `def`'s parameter
types from its body — so an un-inferred capture becomes `PyGetItem ?m …` and instance resolution
gets stuck. Each local below is only pinned down by a *later* statement, not by its initialiser.
-/
-- `graph` starts as `{}`; its key/value types come from the loop that fills it, and the loop target
-- is a TUPLE (`for a, b in pairs`) — which the inference used to skip entirely.
private def _pick_first_one := fun (pairs : List (List Int)) ↦ fun (graph : Std.HashMap Int Int) ↦
  Id.run
    (do
      for u in (PastaLean.pyIter (PastaLean.pyKeys graph))do
        if h_1 : graph⦋u⦌ = (1 : Int) then 
          return u
        else
          let _ := ()
      let __py_ret_1 := pairs⦋(0 : Int)⦌⦋(0 : Int)⦌
      return __py_ret_1)

attribute [simp, taste_ingr] _pick_first_one

def pick := fun (pairs : List (List Int)) ↦
  Id.run
    (do
      let mut graph : Std.HashMap Int Int := Std.HashMap.ofList []
      for _pair_1 in (PastaLean.pyIter pairs)do
        let a := PastaLean.pyListGetItem _pair_1 (0 : Int)
        let b := PastaLean.pyListGetItem _pair_1 (1 : Int)
        graph := PastaLean.pySetItem graph a b
      let __py_ret_1 := _pick_first_one pairs graph
      return __py_ret_1)

attribute [simp, taste_ingr] pick

private def _pick_first_one'rn := fun (pairs : List (List Int)) ↦ fun (graph : Std.HashMap Int Int) ↦
  Id.run
    (do
      for u in (PastaLean.pyIter (PastaLean.pyKeys graph))do
        if h_1 : graph⦋u⦌ == (1 : Int) then 
          return u
        else
          let _ := ()
      let __py_ret_1 := pairs⦋(0 : Int)⦌⦋(0 : Int)⦌
      return __py_ret_1)

def pick'rn := fun (pairs : List (List Int)) ↦
  Id.run
    (do
      let mut graph : Std.HashMap Int Int := Std.HashMap.ofList []
      for _pair_1 in (PastaLean.pyIter pairs)do
        let a := PastaLean.pyListGetItem _pair_1 (0 : Int)
        let b := PastaLean.pyListGetItem _pair_1 (1 : Int)
        graph := PastaLean.pySetItem graph a b
      let __py_ret_1 := _pick_first_one'rn pairs graph
      return __py_ret_1)

-- `seen` is refined by `+=` through a subscript, and `buckets` by `.append` through a subscript.
private def _tally_score := fun (seen : Std.HashMap String Int) ↦ fun (buckets : Std.HashMap Int (List String)) ↦
  Id.run
    (do
      let mut total : Int := (0 : Int)
      for w in (PastaLean.pyIter (PastaLean.pyKeys seen))do
        total := total +ₚ (seen⦋w⦌ +ₚ PastaLean.pyLen buckets⦋PastaLean.pyLen w⦌)
      return total)

attribute [simp, taste_ingr] _tally_score

def tally := fun (words : List String) ↦
  Id.run
    (do
      let mut seen : Std.HashMap String Int := Std.HashMap.ofList []
      let mut buckets : Std.HashMap Int (List String) := Std.HashMap.ofList []
      for w in (PastaLean.pyIter words)do
        seen := PastaLean.pySetItem seen w (PastaLean.pyGetD seen w (0 : Int) +ₚ (1 : Int))
        buckets := PastaLean.pySetItem buckets (PastaLean.pyLen w) []
      for w in (PastaLean.pyIter words)do
        buckets := PastaLean.pySetItem buckets (PastaLean.pyLen w) (PastaLean.pyAppend buckets⦋PastaLean.pyLen w⦌ w)
      let __py_ret_1 := _tally_score seen buckets
      return __py_ret_1)

attribute [simp, taste_ingr] tally

private def _tally_score'rn := fun (seen : Std.HashMap String Int) ↦ fun (buckets : Std.HashMap Int (List String)) ↦
  Id.run
    (do
      let mut total : Int := (0 : Int)
      for w in (PastaLean.pyIter (PastaLean.pyKeys seen))do
        total := total +ₚ (seen⦋w⦌ +ₚ PastaLean.pyLen buckets⦋PastaLean.pyLen w⦌)
      return total)

def tally'rn := fun (words : List String) ↦
  Id.run
    (do
      let mut seen : Std.HashMap String Int := Std.HashMap.ofList []
      let mut buckets : Std.HashMap Int (List String) := Std.HashMap.ofList []
      for w in (PastaLean.pyIter words)do
        seen := PastaLean.pySetItem seen w (PastaLean.pyGetD seen w (0 : Int) +ₚ (1 : Int))
        buckets := PastaLean.pySetItem buckets (PastaLean.pyLen w) []
      for w in (PastaLean.pyIter words)do
        buckets := PastaLean.pySetItem buckets (PastaLean.pyLen w) (PastaLean.pyAppend buckets⦋PastaLean.pyLen w⦌ w)
      let __py_ret_1 := _tally_score'rn seen buckets
      return __py_ret_1)

def main' :=
  ((do
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (pick [[(1 : Int), (1 : Int)], [(2 : Int), (3 : Int)]])]
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (tally ["ab", "ab", "c"])]) :
    PastaLean.ProofMode.PyProofM _)

attribute [simp] main'

def main''rn :=
  ((do
      let _ ← pyPrintIO [pyPrintArg (pick'rn [[(1 : Int), (1 : Int)], [(2 : Int), (3 : Int)]])]
      let _ ← pyPrintIO [pyPrintArg (tally'rn ["ab", "ab", "c"])]) :
    IO _)

def main : IO Unit := do
  let _ := main'
  pure ()

def main'rn : IO Unit := do
  let _ := main''rn
  pure ()