import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure IntList where
  data : PastaLean.Ref (List Int)
  deriving Inhabited, Repr, BEq

structure IntList'rn where
  data : PastaLean.Ref (List Int)
  deriving Inhabited, Repr, BEq

inductive Val where
  | intList (data : PastaLean.Ref (List Int))
  | intList'rn (data : PastaLean.Ref (List Int))
  | hc_List_Int (c : List Int)
  deriving Repr, Inhabited

derive_storable% IntList

derive_storable% IntList'rn

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

-- Container reads/writes beyond append: indexing (read + write) and iteration, all through a
-- heap-allocated list field. Returns 149.
def IntList.new : PastaLean.HeapM Val (PastaLean.Ref IntList) :=
  ((do
      PastaLean.alloc ({ data := (← PastaLean.allocM []) } : IntList)) :
    PastaLean.HeapM Val (PastaLean.Ref IntList))

def IntList.push (self : PastaLean.Ref IntList) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> data) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def IntList.get (self : PastaLean.Ref IntList) (i) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRefM (← self ~> data))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def IntList.set (self : PastaLean.Ref IntList) (i) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> data) (fun __hc_l => PastaLean.pySetItem __hc_l i x)) :
    PastaLean.HeapM Val _)

def IntList.total (self : PastaLean.Ref IntList) :=
  ((do
      let mut s : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM (← self ~> data)))do
        s := s +ₚ v
      return s) :
    PastaLean.HeapM Val _)

def IntList'rn.new : PastaLean.HeapM Val (PastaLean.Ref IntList'rn) :=
  ((do
      PastaLean.alloc ({ data := (← PastaLean.allocM []) } : IntList'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref IntList'rn))

def IntList'rn.push (self : PastaLean.Ref IntList'rn) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> data) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def IntList'rn.get (self : PastaLean.Ref IntList'rn) (i) :=
  ((do
      let __py_ret_1 := (← PastaLean.readRefM (← self ~> data))⦋i⦌
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def IntList'rn.set (self : PastaLean.Ref IntList'rn) (i) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> data) (fun __hc_l => PastaLean.pySetItem __hc_l i x)) :
    PastaLean.HeapM Val _)

def IntList'rn.total (self : PastaLean.Ref IntList'rn) :=
  ((do
      let mut s : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM (← self ~> data)))do
        s := s +ₚ v
      return s) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut xs := (← IntList.new)
      let _ ← IntList.push xs (10 : Int)
      let _ ← IntList.push xs (20 : Int)
      let _ ← IntList.push xs (30 : Int)
      let _ ← IntList.set xs (1 : Int) (99 : Int)
      let __py_ret_1 := (← IntList.total xs) +ₚ (← IntList.get xs (0 : Int))
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut xs := (← IntList'rn.new)
      let _ ← IntList'rn.push xs (10 : Int)
      let _ ← IntList'rn.push xs (20 : Int)
      let _ ← IntList'rn.push xs (30 : Int)
      let _ ← IntList'rn.set xs (1 : Int) (99 : Int)
      let __py_ret_1 := (← IntList'rn.total xs) +ₚ (← IntList'rn.get xs (0 : Int))
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)
