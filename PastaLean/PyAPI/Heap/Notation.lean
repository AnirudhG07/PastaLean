import PastaLean.PyAPI.Heap.Monad

/-!
# Heap runtime — pointer notation

C-style sugar (ported from the `heapsl-nightly` reference design) so generated code reads like the
Python it came from, instead of raw `readRef`/`writeRef`:

* `r ~> f` — **read** field `f` through reference `r`. Elaborates to a `HeapM` *action*, so it is
  used as `(← r ~> f)`. (Keeping the `←` explicit — rather than hiding it inside a term macro — is
  deliberate: the `do` elaborator's nested-action pass can't see a `←` buried in a term macro.)
* `r ~> f <~ v` — **write** field `f` through `r` (whole-cell read-modify-write). Because it expands
  to a `doElem` (`writeRef r { (← readRef r) with f := v }`), `v` may itself contain reads
  (`self.x = self.x + 1`): those `←`s lift to statement level.
* `r <~ v` — overwrite the whole cell `r`.

We deliberately do NOT reuse HeapSL's `set r.f := v` form: `set` collides with `MonadState.set`,
which the code generator itself uses throughout its `do`-blocks.
-/

namespace PastaLean

/-- Read field `f` through reference `r` (C's `r->f`); a heap action, bound with `←`. Uses the
monad-polymorphic `readRefM` so the read works in any heap monad (`HeapM`, `PyHeapIO`,
`PyHeapProofM`) — a bare `readRef` leaves `V` a metavariable outside a `HeapM` body. -/
syntax:max term:max " ~> " ident : term
macro_rules | `($r ~> $f) => `(do return (← PastaLean.readRefM $r).$f)

/-- Write through a reference (statement form). `r <~ v` overwrites the whole cell; `r ~> f <~ v`
overwrites one field via a whole-cell read-modify-write. Named (`ptrWrite`) so codegen can build the
node directly — the infix `<~` doesn't survive a `doElem` quotation with an antiquote LHS. -/
syntax:min (name := ptrWrite) term:max " <~ " term : doElem
open Lean in
macro_rules
  | `(doElem| $lhs:term <~ $v:term) => do
      match lhs with
      | `($r ~> $f:ident) =>
          `(doElem| PastaLean.writeRefM $r { (← PastaLean.readRefM $r) with $f:ident := $v })
      | _ => `(doElem| PastaLean.writeRefM $lhs $v)

end PastaLean
