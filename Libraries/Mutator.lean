import Lean

namespace Libraries

/-- How a library member mutates its FIRST argument in place, declared BY the library so the core
code generator can lower it without hardcoding any library's names (the mutation analogue of
`pythonLibraryMap?`). A call `f(x, …)`:
* as a statement lowers to `x := stmtFn x …`;
* as `y = f(x, …)`, when `valueRest?` is set, lowers to `y := valFn x …; x := restFn x …`. -/
structure LibraryMutator where
  stmtFn : Lean.Name
  valueRest? : Option (Lean.Name × Lean.Name) := none

/-- An iterator with no end. Iterators are modelled as strict `List`s, so these have no runtime
value at all; instead `for x in f(…)` is desugared to `while True` with `x` advanced at the top of
the body (see `unrollInfiniteIter`). A library declares its members here — the constructor names the
*shape* of that advance, and the desugaring supplies it.

* `counter` — `f(start := 0, step := 1)`: `x` starts at `start` and grows by `step`.
* `cyclic` — `f(xs)`: `x` walks `xs` from the top, forever.
* `constant` — `f(x)`: every iteration yields the same value.

Anything used OUTSIDE a `for` header (`islice(count(), 5)`, say) is still unsupported and keeps its
existing error — unrolling is what makes these finite, so there is nothing to unroll into. -/
inductive InfiniteIter
  | counter
  | cyclic
  | constant
  deriving BEq, Repr

end Libraries
