import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Bag where
  items : PastaLean.Ref (List Int)
  deriving Inhabited, Repr, BEq

structure Bag'rn where
  items : PastaLean.Ref (List Int)
  deriving Inhabited, Repr, BEq

inductive Val where
  | bag (items : PastaLean.Ref (List Int))
  | bag'rn (items : PastaLean.Ref (List Int))
  | hc_List_Int (c : List Int)
  deriving Repr, Inhabited

derive_storable% Bag

derive_storable% Bag'rn

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

-- Container reference semantics through a shared object: two handles to the same Bag share the same
-- underlying heap list, so appends through either are visible via the other. Returns 3.
def Bag.new : PastaLean.HeapM Val (PastaLean.Ref Bag) :=
  ((do
      PastaLean.alloc ({ items := (← PastaLean.allocM []) } : Bag)) :
    PastaLean.HeapM Val (PastaLean.Ref Bag))

def Bag.add (self : PastaLean.Ref Bag) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Bag.size (self : PastaLean.Ref Bag) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def Bag'rn.new : PastaLean.HeapM Val (PastaLean.Ref Bag'rn) :=
  ((do
      PastaLean.alloc ({ items := (← PastaLean.allocM []) } : Bag'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Bag'rn))

def Bag'rn.add (self : PastaLean.Ref Bag'rn) (x) :=
  ((do
      PastaLean.modifyRefM (← self ~> items) (fun __hc_l => PastaLean.pyAppend __hc_l x)) :
    PastaLean.HeapM Val _)

def Bag'rn.size (self : PastaLean.Ref Bag'rn) :=
  ((do
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← self ~> items))
      return __py_ret_1) :
    PastaLean.HeapM Val _)

def demo :=
  ((do
      let mut a := (← Bag.new)
      let mut b := a
      let _ ← Bag.add a (1 : Int)
      let _ ← Bag.add b (2 : Int)
      let _ ← Bag.add b (3 : Int)
      let __py_ret_1 := (← Bag.size a)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] demo

def demo'rn :=
  ((do
      let mut a := (← Bag'rn.new)
      let mut b := a
      let _ ← Bag'rn.add a (1 : Int)
      let _ ← Bag'rn.add b (2 : Int)
      let _ ← Bag'rn.add b (3 : Int)
      let __py_ret_1 := (← Bag'rn.size a)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)
