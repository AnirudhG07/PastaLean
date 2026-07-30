import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

structure Counter where
  n : Int
  deriving Inhabited, Repr, BEq

structure Counter'rn where
  n : Int
  deriving Inhabited, Repr, BEq

inductive Val where
  | counter (n : Int)
  | counter'rn (n : Int)
  | hc_Float (c : Float)
  | hc_Bool (c : Bool)
  | hc_String (c : String)
  | hc_Rat (c : Rat)
  | hc_Int (c : Int)
  | hc_Ref_Counter_rn (c : Ref Counter'rn)
  | hc_Ref_Counter (c : Ref Counter)
  deriving Repr, Inhabited

derive_storable% Counter

derive_storable% Counter'rn

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

instance : Storable Val (Ref Counter'rn) where
  inject := Val.hc_Ref_Counter_rn
  project := fun
    | Val.hc_Ref_Counter_rn c => some c
    | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Ref Counter) where
  inject := Val.hc_Ref_Counter
  project := fun
    | Val.hc_Ref_Counter c => some c
    | _ => none
  project_inject := fun _ => rfl

-- Passing a user OBJECT across a function boundary (--heap). Under reference semantics an object
-- parameter is `Ref C`, so a free function can mutate the caller's object in place. Field READS
-- dereference (`(← c ~> n)`); field WRITES lower to the pointer write `c ~> attr <~ v` — both the plain
-- assign `c.n = v` and the aug-assign `c.n += k` (which reads-then-writes through the ref). The function
-- joins the heap tier and callers await it. Boundary cases: aug-write, plain write, a pure reader, two
-- object params, and mutation observed both via a reader and by direct field access on the caller's ref.
def Counter.new : Int → PastaLean.HeapM Val (PastaLean.Ref Counter) := fun (n : Int) ↦
  ((do
      PastaLean.alloc ({ n := n } : Counter)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter))

def Counter'rn.new : Int → PastaLean.HeapM Val (PastaLean.Ref Counter'rn) := fun (n : Int) ↦
  ((do
      PastaLean.alloc ({ n := n } : Counter'rn)) :
    PastaLean.HeapM Val (PastaLean.Ref Counter'rn))

def bump := fun (c : PastaLean.Ref Counter) ↦ fun (k : Int) ↦
  ((do
      c ~> n <~ (← c ~> n) +ₚ k) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] bump

def bump'rn := fun (c : PastaLean.Ref Counter'rn) ↦ fun (k : Int) ↦
  ((do
      c ~> n <~ (← c ~> n) +ₚ k) :
    (PastaLean.HeapM Val) _)

def reset := fun (c : PastaLean.Ref Counter) ↦ fun (v : Int) ↦
  ((do
      c ~> n <~ v) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] reset

def reset'rn := fun (c : PastaLean.Ref Counter'rn) ↦ fun (v : Int) ↦
  ((do
      c ~> n <~ v) :
    (PastaLean.HeapM Val) _)

def value_of := fun (c : PastaLean.Ref Counter) ↦
  ((do
      let __py_ret_1 := (← c ~> n)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] value_of

def value_of'rn := fun (c : PastaLean.Ref Counter'rn) ↦
  ((do
      let __py_ret_1 := (← c ~> n)
      return __py_ret_1) :
    (PastaLean.HeapM Val) _)

def move := fun (dst : PastaLean.Ref Counter) ↦ fun (src : PastaLean.Ref Counter) ↦
  ((do
      dst ~> n <~ (← src ~> n)) :
    (PastaLean.HeapM Val) _)

attribute [simp, taste_ingr] move

def move'rn := fun (dst : PastaLean.Ref Counter'rn) ↦ fun (src : PastaLean.Ref Counter'rn) ↦
  ((do
      dst ~> n <~ (← src ~> n)) :
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
        let mut c := (← Counter.new (5 : Int))
        let _ ← bump c (10 : Int)
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← value_of c)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← c ~> n)]
        let _ ← reset c (3 : Int)
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← c ~> n)]
        let mut d := (← Counter.new (99 : Int))
        let _ ← move c d
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← c ~> n)]
        let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (← d ~> n)]
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
          let mut c := (← Counter'rn.new (5 : Int))
          let _ ← bump'rn c (10 : Int)
          let _ ← pyPrintIO [pyPrintArg (← value_of'rn c)]
          let _ ← pyPrintIO [pyPrintArg (← c ~> n)]
          let _ ← reset'rn c (3 : Int)
          let _ ← pyPrintIO [pyPrintArg (← c ~> n)]
          let mut d := (← Counter'rn.new (99 : Int))
          let _ ← move'rn c d
          let _ ← pyPrintIO [pyPrintArg (← c ~> n)]
          let _ ← pyPrintIO [pyPrintArg (← d ~> n)]
          pure ())
  match result with
  | .ok _ =>
    pure ()
  | .error err =>
    throw (IO.userError (toString err))
