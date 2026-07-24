/-!
# Stateful closures via reference cells

A Python closure that **mutates a captured variable** and **escapes** (is returned / stored) — the
classic counter factory —

```python
def counter():
    c = 0
    def inc():
        nonlocal c        # (or the object idiom: c = [0]; c[0] += 1)
        c += 1
        return c
    return inc            # inc escapes, carrying c
```

cannot be lowered like a read-only closure: the two `inc()` calls made by whoever holds the returned
closure must **share one cell** and see each other's writes. A Lean closure captures a value, not a
mutable slot, so we lower the captured cell to a real reference: `IO.Ref`. `counter` allocates the
ref and returns a closure that reads/writes it.

`IO` is opaque — there is no equational theory to prove the `IO.Ref` program against. But the closure's
*intended* meaning is referentially transparent: a pure **state transformer**. We specify that here
and prove it, so the semantics the `IO` lowering implements is pinned down and verified.
-/

namespace PastaLean

/-- The mutable cell backing an escaping stateful closure. The `counter`/`inc` lowering allocates one
with `pyMkRef` and the returned closure closes over it. -/
abbrev PyRef (α : Type) := IO.Ref α

@[inline] def pyMkRef {α : Type} (init : α) : IO (PyRef α) := IO.mkRef init
@[inline] def pyRefGet {α : Type} (r : PyRef α) : IO α := r.get
@[inline] def pyRefSet {α : Type} (r : PyRef α) (v : α) : IO Unit := r.set v
/-- `nonlocal c; c = f c; return c` on the cell: update in place and return the new value. -/
@[inline] def pyRefUpdateGet {α : Type} (r : PyRef α) (f : α → α) : IO α := do
  r.modify f; r.get

/-! ## Correctness of the `inc` closure

The pure specification the `IO.Ref` lowering implements: `inc` is `modify (·+1); get` in `StateM`. -/

/-- One `inc()` call: increment the shared cell, return the new value. -/
def counterStep : StateM Nat Nat := do modify (· + 1); get

/-- Each call increments the cell by one and returns exactly that value — the closure's per-call law. -/
theorem counterStep_run (s : Nat) : counterStep.run s = (s + 1, s + 1) := rfl

/-- Run `inc` `k` times from cell value `s`, returning the final value. -/
def runCounter : Nat → Nat → Nat
  | 0,     s => s
  | k + 1, s => runCounter k (counterStep.run s).2

/-- **The counter counts.** Running `inc` `k` times from `s` leaves the shared cell at `s + k` — so
from `0` the `k`-th call returns `k`. This is exactly "the returned closure remembers its state across
calls", proved by induction: the shared cell is a faithful running total. -/
theorem counter_counts (s k : Nat) : runCounter k s = s + k := by
  induction k generalizing s with
  | zero => rfl
  | succ n ih =>
      show runCounter n (counterStep.run s).2 = s + (n + 1)
      rw [counterStep_run, ih]; omega

end PastaLean
