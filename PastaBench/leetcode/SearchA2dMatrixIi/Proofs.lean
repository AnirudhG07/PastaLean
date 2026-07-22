import PastaBench.leetcode.SearchA2dMatrixIi.Generated

/-!
# search-a-2d-matrix-ii — hand-written proofs  (Medium, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only SearchA2dMatrixIi` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem searchMatrix_spec' : <the generated statement> := by
  <hand-written proof>

example : searchMatrix_spec = searchMatrix_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.SearchA2dMatrixIi

-- TODO: state and prove the correctness theorem for `searchMatrix`.

end PastaBench.leetcode.SearchA2dMatrixIi
