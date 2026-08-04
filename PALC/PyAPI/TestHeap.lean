import PastaLean.PyAPI.Heap

/-!
# Heap runtime unit checks (`--heap` reference semantics)

Exercises the heap monad against a small hand-written value universe of the same *kind* the
`HeapPrelude` generator emits: a top-level `Val` inductive, the concrete `Storable Val …` instances,
and `derive_storable%` per struct. (This test universe is intentionally element-wise — it has
primitive constructors and a recursive `arr` case — whereas the generator emits no primitive
constructors and stores each container whole in one cell; both shapes drive the same runtime.) These
`#guard_msgs`/`#eval` checks fire at build time.
-/

open PastaLean

namespace HeapTest

/-- A tiny mutable object, standing in for a translated Python class. -/
structure Counter where
  count : Int
  deriving Repr, DecidableEq, Inhabited

end HeapTest

open HeapTest in
/-- The per-program value universe (what `HeapPrelude` generates). -/
inductive Val where
  | int  (n : Int)
  | str  (s : String)
  | addr (a : Nat)
  | arr  (vs : List Val)
  | counter (count : Int)
  deriving Repr, Inhabited

/-! Concrete `Storable Val …` instances — generated into the program, not part of the runtime. -/

instance : Storable Val Int where
  inject := .int
  project := fun | .int n => some n | _ => none
  project_inject := fun _ => rfl

instance : Storable Val String where
  inject := .str
  project := fun | .str s => some s | _ => none
  project_inject := fun _ => rfl

instance : Storable Val (Ref α) where
  inject r := .addr r.addr
  project := fun | .addr a => some ⟨a⟩ | _ => none
  project_inject := fun _ => rfl

instance [Storable Val α] : Storable Val (List α) where
  inject xs := .arr (xs.map Storable.inject)
  project := fun | .arr vs => projectList vs | _ => none
  project_inject xs := projectList_map_inject xs

derive_storable% HeapTest.Counter

open HeapTest

/-! ## alloc / readRef round-trip -/

/-- info: Except.ok 5 -/
#guard_msgs in
#eval eval (V := Val) do
  let r ← alloc (5 : Int)
  readRef r

/-! ## writeRef overwrites -/

/-- info: Except.ok 42 -/
#guard_msgs in
#eval eval (V := Val) do
  let r ← alloc (1 : Int)
  writeRef r 42
  readRef r

/-! ## modifyRef read-modify-writes -/

/-- info: Except.ok 15 -/
#guard_msgs in
#eval eval (V := Val) do
  let r ← alloc (10 : Int)
  modifyRef r (· + 5)
  readRef r

/-! ## Aliasing: a mutation through one binding is visible through the other -/

/-- info: Except.ok { count := 1 } -/
#guard_msgs in
#eval eval (V := Val) do
  let a ← alloc ({ count := 0 } : Counter)
  let b := a  -- alias (same address)
  modifyRef b (fun c => { c with count := c.count + 1 })
  readRef a

/-! ## Heap-allocated list, mutated in place through the ref -/

/-- info: Except.ok [1, 2, 3, 4] -/
#guard_msgs in
#eval eval (V := Val) do
  let xs ← alloc ([1, 2, 3] : List Int)
  modifyRef xs (fun l => l ++ [4])
  readRef xs

/-! ## Exceptions keep heap mutations (non-restoring `Backtrackable`, matching Python):
a mutation performed *inside* a `try` before the `raise` survives the `except`. -/

/-- info: Except.ok 99 -/
#guard_msgs in
#eval eval (V := Val) do
  let r ← alloc (7 : Int)
  try
    writeRef r 99
    throw (PyException.Raise "ValueError" "boom")
  catch _ =>
    pure ()
  readRef r

/-! ## A dangling reference read surfaces as a translated `PyException`. -/

/-- info: Except.error { kind := "ReferenceError", msg := "dangling reference at address 5" } -/
#guard_msgs in
#eval eval (V := Val) do
  readRef (α := Int) ⟨5⟩
