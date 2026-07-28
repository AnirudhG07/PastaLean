import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

inductive Val where
  | hc_List_Int (c : List Int)
  deriving Repr, Inhabited

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
  project_inject := fun _ => rfl

-- A bare local list (no class): built, aliased, mutated through the alias, iterated, and indexed.
-- `ys = xs` shares the same heap list, so `ys.append` is visible via `xs`. Returns 7.
def demo :=
  ((do
      let mut xs := (← PastaLean.allocM [(1 : Int)])
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l (2 : Int))
      let mut ys := xs
      PastaLean.modifyRefM ys (fun __hc_l => PastaLean.pyAppend __hc_l (3 : Int))
      let mut total : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM xs))do
        total := total +ₚ v
      let __py_ret_1 := total +ₚ (← PastaLean.readRefM xs)⦋(0 : Int)⦌
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut xs := (← PastaLean.allocM [(1 : Int)])
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l (2 : Int))
      let mut ys := xs
      PastaLean.modifyRefM ys (fun __hc_l => PastaLean.pyAppend __hc_l (3 : Int))
      let mut total : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM xs))do
        total := total +ₚ v
      let __py_ret_1 := total +ₚ (← PastaLean.readRefM xs)⦋(0 : Int)⦌
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)
