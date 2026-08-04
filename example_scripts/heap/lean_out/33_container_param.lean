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

-- Passing a mutable CONTAINER across a function boundary (--heap). Under reference semantics a
-- `list`/`dict`/`set` parameter is the object-ref itself (`Ref (List Int)`), so the function joins the
-- heap tier (`HeapM Val`) and its callers await it. Every consumption inside the callee dereferences
-- the ref: `len`/subscript/iteration read it, `.append` mutates it in place (visible to the caller).
-- Boundary cases: a pure reader, a returns-None mutator, multiple container params, transitive passing
-- (a container param handed to another container-param function), and a shared list mutated then re-read.
def total := fun (xs : PastaLean.Ref (List Int)) ↦
  ((do
      let mut s : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM xs))do
        s := s +ₚ v
      return s) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] total

def total'rn := fun (xs : PastaLean.Ref (List Int)) ↦
  ((do
      let mut s : Int := (0 : Int)
      for v in (PastaLean.pyIter (← PastaLean.readRefM xs))do
        s := s +ₚ v
      return s) :
    (PastaLean.HeapM Val) _)

def first := fun (xs : PastaLean.Ref (List Int)) ↦
  ((do
      let __py_ret_1 := (← PastaLean.readRefM xs)⦋(0 : Int)⦌
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] first

def first'rn := fun (xs : PastaLean.Ref (List Int)) ↦
  ((do
      let __py_ret_1 := (← PastaLean.readRefM xs)⦋(0 : Int)⦌
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

def push_twice := fun (xs : PastaLean.Ref (List Int)) ↦ fun (v : Int) ↦
  ((do
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l v)
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l v)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] push_twice

def push_twice'rn := fun (xs : PastaLean.Ref (List Int)) ↦ fun (v : Int) ↦
  ((do
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l v)
      PastaLean.modifyRefM xs (fun __hc_l => PastaLean.pyAppend __hc_l v)) :
    (PastaLean.HeapM Val) _)

def extend_with := fun (dst : PastaLean.Ref (List Int)) ↦ fun (src : PastaLean.Ref (List Int)) ↦
  ((do
      for v in (PastaLean.pyIter (← PastaLean.readRefM src))do
        PastaLean.modifyRefM dst (fun __hc_l => PastaLean.pyAppend __hc_l v)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] extend_with

def extend_with'rn := fun (dst : PastaLean.Ref (List Int)) ↦ fun (src : PastaLean.Ref (List Int)) ↦
  ((do
      for v in (PastaLean.pyIter (← PastaLean.readRefM src))do
        PastaLean.modifyRefM dst (fun __hc_l => PastaLean.pyAppend __hc_l v)) :
    (PastaLean.HeapM Val) _)

def grow_then_total := fun (xs : PastaLean.Ref (List Int)) ↦ fun (v : Int) ↦
  ((do
      let _ ← push_twice xs v
      let __py_ret_1 := (← total xs)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] grow_then_total

def grow_then_total'rn := fun (xs : PastaLean.Ref (List Int)) ↦ fun (v : Int) ↦
  ((do
      let _ ← push_twice'rn xs v
      let __py_ret_1 := (← total'rn xs)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

def main : IO Unit := do
  let inputText ← IO.getStdin >>= fun h => h.readToEnd
  let inputLines := String.splitOn inputText "\n"
  let inputStream : PastaLean.ProofMode.IOStream :=
    ⟨0, fun i => PastaLean.ProofMode.IOResult.success (List.getD inputLines i "")⟩
  let initState : PastaLean.HeapIOState Val := ⟨PastaLean.emptyHeap, ⟨inputStream, []⟩⟩
  let (result, finalState) :=
    PastaLean.PyHeapProofM.runProgram (V := Val)
      (do
        let mut ys := (← PastaLean.allocM [(1 : Int), (2 : Int), (3 : Int)])
        let _ ← push_twice ys (10 : Int)
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← total ys)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← first ys)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
        let mut more := (← PastaLean.allocM [(100 : Int), (200 : Int)])
        let _ ← extend_with ys more
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← total ys)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← grow_then_total ys (1 : Int))]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
        pure ())
      initState
  let outputLines := finalState.io.output
  for line in outputLines do
    IO.print line
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))

def main'rn : IO Unit := do
  let (result, _heap) ←
    PastaLean.PyHeapIO.runProgram (V := Val)
        (do
          let mut ys := (← PastaLean.allocM [(1 : Int), (2 : Int), (3 : Int)])
          let _ ← push_twice'rn ys (10 : Int)
          let _ ← pyPrintIO [pyPrintArg (← total'rn ys)]
          let _ ← pyPrintIO [pyPrintArg (← first'rn ys)]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
          let mut more := (← PastaLean.allocM [(100 : Int), (200 : Int)])
          let _ ← extend_with'rn ys more
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
          let _ ← pyPrintIO [pyPrintArg (← total'rn ys)]
          let _ ← pyPrintIO [pyPrintArg (← grow_then_total'rn ys (1 : Int))]
          let _ ← pyPrintIO [pyPrintArg (PastaLean.pyLen (← PastaLean.readRefM ys))]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
