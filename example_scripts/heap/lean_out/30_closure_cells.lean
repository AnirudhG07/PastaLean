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
  | hc_Float (c : Float)
  | hc_Bool (c : Bool)
  | hc_String (c : String)
  | hc_Rat (c : Rat)
  | hc_Int (c : Int)
  | hc_Ref__List_Int_ (c : Ref (List Int))
  deriving Repr, Inhabited

instance : Storable Val (List Int) where
  inject := Val.hc_List_Int
  project := fun
    | Val.hc_List_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Float) where
  inject := Val.hc_Float
  project := fun
    | Val.hc_Float c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Bool) where
  inject := Val.hc_Bool
  project := fun
    | Val.hc_Bool c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (String) where
  inject := Val.hc_String
  project := fun
    | Val.hc_String c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Rat) where
  inject := Val.hc_Rat
  project := fun
    | Val.hc_Rat c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Int) where
  inject := Val.hc_Int
  project := fun
    | Val.hc_Int c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Ref (List Int)) where
  inject := Val.hc_Ref__List_Int_
  project := fun
    | Val.hc_Ref__List_Int_ c => some c
    | _ => none
  project_inject := fun _ => rfl

-- Closure-captured, MUTATED variables under reference semantics (--heap) become shared variable CELLS,
-- passed by ref into the capturing sibling — the headline of the cell-sharing model. Two cell shapes:
-- - a mutable CONTAINER capture (`xs.append`) → double ref `Ref (Ref (List Int))`: the rebindable
-- binding (outer ref) and the aliasable object (inner ref). Appends through the closure are seen
-- through `alias`, a second name bound to the SAME object → ([1,2,3,4], [1,2,3,4]).
-- - a mutable SCALAR capture (`nonlocal count`) → single ref `Ref Int`: only the binding is shared,
-- so both `bump` calls accumulate into it → 5 + 3 == 8.
-- Both cells are compile-checked here as defs (a scalar-cell function is not yet callable from a
-- non-heap context — the driver can't see the Lean-side cell promotion to stamp `_heap_call`).
private def _aliased_list_closure'push := fun (v : Int) ↦ fun (xs : PastaLean.Ref (PastaLean.Ref (List Int))) ↦
  ((do
      PastaLean.modifyRefM (← PastaLean.readRefM xs) (fun __hc_l => PastaLean.pyAppend __hc_l v)
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← PastaLean.readRefM xs))
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] _aliased_list_closure'push

def aliased_list_closure :=
  ((do
      let mut xs := (← PastaLean.allocM (← PastaLean.allocM [(1 : Int), (2 : Int)]))
      let mut «alias» := (← PastaLean.readRefM xs)
      let _ ← _aliased_list_closure'push (3 : Int) xs
      let _ ← _aliased_list_closure'push (4 : Int) xs
      let __py_ret_1 := ((← PastaLean.readRefM xs), «alias»)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] aliased_list_closure

private def _aliased_list_closure'push'rn := fun (v : Int) ↦ fun (xs : PastaLean.Ref (PastaLean.Ref (List Int))) ↦
  ((do
      PastaLean.modifyRefM (← PastaLean.readRefM xs) (fun __hc_l => PastaLean.pyAppend __hc_l v)
      let __py_ret_1 := PastaLean.pyLen (← PastaLean.readRefM (← PastaLean.readRefM xs))
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

def aliased_list_closure'rn :=
  ((do
      let mut xs := (← PastaLean.allocM (← PastaLean.allocM [(1 : Int), (2 : Int)]))
      let mut «alias» := (← PastaLean.readRefM xs)
      let _ ← _aliased_list_closure'push'rn (3 : Int) xs
      let _ ← _aliased_list_closure'push'rn (4 : Int) xs
      let __py_ret_1 := ((← PastaLean.readRefM xs), «alias»)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

private def _counter_closure'bump := fun (k : Int) ↦ fun (count : PastaLean.Ref Int) ↦
  ((do
      PastaLean.writeRefM count ((← PastaLean.readRefM count) +ₚ k)
      return (← PastaLean.readRefM count)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] _counter_closure'bump

def counter_closure :=
  ((do
      let mut count := (← PastaLean.allocM (0 : Int))
      let _ ← _counter_closure'bump (5 : Int) count
      let _ ← _counter_closure'bump (3 : Int) count
      return (← PastaLean.readRefM count)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] counter_closure

private def _counter_closure'bump'rn := fun (k : Int) ↦ fun (count : PastaLean.Ref Int) ↦
  ((do
      PastaLean.writeRefM count ((← PastaLean.readRefM count) +ₚ k)
      return (← PastaLean.readRefM count)) :
    (PastaLean.HeapM Val) _)

def counter_closure'rn :=
  ((do
      let mut count := (← PastaLean.allocM (0 : Int))
      let _ ← _counter_closure'bump'rn (5 : Int) count
      let _ ← _counter_closure'bump'rn (3 : Int) count
      return (← PastaLean.readRefM count)) :
    (PastaLean.HeapM Val) _)
