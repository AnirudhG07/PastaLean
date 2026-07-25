# Array-backing the `'rn` twin — staged codegen wiring

**Goal:** the runnable (`'rn`/approx) twin backs Python `list` with `Array α` (O(1) append/index via
Perceus in-place reuse; validated ~134× at n=30k), keeping the provable twin on `List α`. A list
value is `Array` by default and **falls back to `List`** when it uses an op where Array is O(n²) but
List is O(n) (prepend / `insert(0,·)` / `pop(0)` / head-tail recursion) or an op not ported to Array.
The choice is **per value, compile-time** (no runtime toList↔toArray) → no consistency bugs.

## Emission points (all must agree on a value's backing)
1. Type: `functionArgTypeSyntax?` (FuncDef) + `pyTypeSyntax?` (CallShared) — `list[T]` → `Array T` / `List T`.
2. Literal: `List` node (Basic.lean) — `#[…]` vs `[…]`.
3. Concrete fns: `pyAppend`/`pyListRepeat`/`pyExtend`/`pyInsert`/`pyListPop`/`pySliceSet`/`pyReverse` →
   `pyArray*` (Attributes.lean / CallShared / CallExpr / Assign tuple-unpack `pyListGetItem`).
4. Comprehensions (ListComp) + casts (`list(...)`) producing a stored list.
Protocol ops (`⦋⦌`/`pySetItem`/`pyLen`/`pyIter`/`pyContains`/`pyTruthy`) need NO change — they dispatch
by type once the binder is `Array T` (instances already added in `PyAPI/Arrays.lean`).

## Eligibility (TypeInfer) — a list value is `array_ok` iff
- every use is in the ported set {append, subscript get/set, len, iter, membership, truthy, `[x]*n`,
  extend, comprehension-build}, AND
- it stays consistent across flow (assignment / arg / return / container element) with other array_ok
  lists. Monotone downgrade to List on any unported/List-favorable use or contact with a List value.

## Stages (test after each; default unchanged until green)
- [x] **S1 plumbing** — type (`functionArgTypeSyntax?` + `seqAwareTypeSyntax?`)/literal (`List` node)/
      hoist-type-map/value-ascription emission produce Array, gated on a `_seq:"array"` stamp + approx.
- [x] **S2 activate** — `arrayEligibleVars` (TypeInfer) marks eligible locals; `stampArraySeqs` stamps
      binder `_ty`, nested literals, hoist maps, value ascriptions, and append/extend calls. Codegen
      backs them `Array`. VERIFIED: appchk/mat compile + run correct + **O(1)** (0ms at n=100k vs List
      1473ms at n=30k); `Array (Array Int)` matrix + `Array (Array PyAny)` work; **PALC 90/0**, corpus
      sample **48/60 = baseline** (no regression).
      - append is dispatched in CODEGEN (`pyArrayAppend`, `_seq`-stamped call), NOT by a polymorphic
        `pyAppend` — a protocol left the container a stuck metavariable on untyped nested-helper
        accumulators (regressed binary-tree-traversal). `pyAppend`/`pyExtend` stay monomorphic on `List`.
      - NESTED lists: eligible only as a FULL non-empty literal accessed by index (no append — an
        appended row's backing can't be guaranteed, which is what broke `cnn`).
- [ ] **S3 coverage** — comprehension/`[x]*n` inits → Array (needs `pyArrayRepeat` + ListComp→Array);
      params/returns (interprocedural consistency); nested append via row-backing propagation.
- [ ] **S4 measure** — re-run corpus timeout set; quantify recovered problems.

## Status: S1 + S2 DONE (regression-free). S3/S4 next.
## Tests: PALC/PyAPI/TestLists.lean (Array ops, nested `Array (Array Int)`, `Array (Array PyAny)`, parity).
