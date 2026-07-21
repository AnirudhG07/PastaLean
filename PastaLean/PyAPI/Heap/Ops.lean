import PastaLean.PyAPI.Heap.Storable

/-!
# Heap runtime — operations and runners

`alloc`/`writeRef`/`readRef`/`modifyRef` and the pure runners `run`/`eval`. The leaf ops
(`alloc`/`writeRef`/`readRef`) are written in the base monad (`show HeapBase V _ from …`) so `.run`
exposes them to the base `EStateM` `get`/`set`/`modifyGet`/`throw` wp lemmas the Phase-2 leaf specs
need; `modifyRef` is then defined in terms of them.
-/

namespace PastaLean

variable {V α : Type}

/-- Allocate a storable value at the fresh address `next`, returning a typed reference. -/
def alloc [Storable V α] (v : α) : HeapM V (Ref α) :=
  show HeapBase V _ from
    modifyGet fun h =>
      (⟨h.next⟩, ⟨Store.update h.store h.next (Storable.inject v), h.next + 1, wf_alloc h _⟩)

/-- Overwrite a typed reference. The frontier `next` moves to `max next (r.addr+1)` so the result is
well-formed even for a forged out-of-range reference. -/
def writeRef [Storable V α] (r : Ref α) (v : α) : HeapM V Unit :=
  show HeapBase V _ from
    modify fun h =>
      ⟨Store.update h.store r.addr (Storable.inject v), max h.next (r.addr + 1), wf_write h _ _⟩

/-- Read through a typed reference. Throws a translated Python exception if the address is
unallocated (`ReferenceError`) or holds a different kind than `α` (`TypeError`). In well-typed
generated code these never fire; they exist so the operation composes with `PyException`. -/
def readRef [Storable V α] (r : Ref α) : HeapM V α :=
  show HeapBase V _ from do
    let h ← get
    match h.store r.addr with
    | none   => throw (PyException.Raise "ReferenceError" s!"dangling reference at address {r.addr}")
    | some v =>
      match Storable.project (α := α) v with
      | some a => return a
      | none   => throw (PyException.Raise "TypeError" s!"heap cell {r.addr} holds a different kind")

/-- Read-modify-write: every field/element update reduces to this. Kept a real `def` so Phase 2 can
give it its own `@[spec]`. -/
def modifyRef [Storable V α] (r : Ref α) (f : α → α) : HeapM V Unit := do
  writeRef r (f (← readRef r))

/-! ## Runners -/

/-- The empty heap. -/
def emptyHeap : Heap V := ⟨fun _ => none, 0, fun _ _ => rfl⟩

/-- Run a heap program from a given starting heap, returning the result (an `Except`) and the final
heap. The final heap is returned even on error, so mutations before a `raise` are observable. -/
def runFrom {β : Type} (m : HeapM V β) (h₀ : Heap V) : Except PyException β × Heap V :=
  match (HeapM.run m).run h₀ with
  | .ok a h    => (.ok a, h)
  | .error e h => (.error e, h)

/-- Run a heap program from the empty heap. -/
def run {β : Type} (m : HeapM V β) : Except PyException β × Heap V := runFrom m emptyHeap

/-- Run a heap program from the empty heap, discarding the final heap. -/
def eval {β : Type} (m : HeapM V β) : Except PyException β := (run m).1

end PastaLean
