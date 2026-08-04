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
  | hc_List__Unit___String_ (c : List (Unit → String))
  | hc_Float (c : Float)
  | hc_Bool (c : Bool)
  | hc_String (c : String)
  | hc_Rat (c : Rat)
  | hc_Int (c : Int)
  | hc_Ref__List__Unit___String__ (c : Ref (List (Unit → String)))
  deriving Repr, Inhabited

instance : Storable Val (List (Unit → String))
    where
  inject := Val.hc_List__Unit___String_
  project := fun
    | Val.hc_List__Unit___String_ c => some c
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

instance : Storable Val (Ref (List (Unit → String)))
    where
  inject := Val.hc_Ref__List__Unit___String__
  project := fun
    | Val.hc_Ref__List__Unit___String__ c => some c
    | _ => none
  project_inject := fun _ => rfl

-- A heap-allocated list of closures: `f = []` becomes a `Ref (List (Unit → String))`, and the
-- appended lambdas make the element a function type. The empty `allocM []` can't infer the element's
-- function-domain universe, so the local must be ascribed from its inferred `list[Callable[[], str]]`.
def functions_append_closure :=
  ((do
      let mut f : PastaLean.Ref (List (Unit → String)) := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange (3 : Int))do
        PastaLean.modifyRefM f (fun __hc_l => PastaLean.pyAppend __hc_l fun () ↦ s! "Function {i}")
      for i in (PastaLean.pyRange (3 : Int))do
        PastaLean.modifyRefM f
            (fun __hc_l =>
              PastaLean.pyAppend __hc_l fun () ↦
                let i := i
                s! "Function {i}")
      for func in (PastaLean.pyIter (← PastaLean.readRefM f))do
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (func ())]) :
    (PastaLean.PyHeapProofM Val) _)

attribute [simp] functions_append_closure

def functions_append_closure'rn :=
  ((do
      let mut f : PastaLean.Ref (List (Unit → String)) := (← PastaLean.allocM [])
      for i in (PastaLean.pyRange (3 : Int))do
        PastaLean.modifyRefM f (fun __hc_l => PastaLean.pyAppend __hc_l fun () ↦ s! "Function {i}")
      for i in (PastaLean.pyRange (3 : Int))do
        PastaLean.modifyRefM f
            (fun __hc_l =>
              PastaLean.pyAppend __hc_l fun () ↦
                let i := i
                s! "Function {i}")
      for func in (PastaLean.pyIter (← PastaLean.readRefM f))do
        let _ ← pyPrintIO [pyPrintArg (func ())]) :
    (PastaLean.PyHeapIO Val) _)
