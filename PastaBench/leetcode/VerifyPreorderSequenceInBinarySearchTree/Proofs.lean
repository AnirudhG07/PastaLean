import PastaBench.leetcode.VerifyPreorderSequenceInBinarySearchTree.Generated

/-!
# verify-preorder-sequence-in-binary-search-tree — hand-written proofs  (Medium, bucket `loop`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only VerifyPreorderSequenceInBinarySearchTree` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem verifyPreorder_spec' : <the generated statement> := by
  <hand-written proof>

example : verifyPreorder_spec = verifyPreorder_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.VerifyPreorderSequenceInBinarySearchTree

-- TODO: state and prove the correctness theorem for `verifyPreorder`.

end PastaBench.leetcode.VerifyPreorderSequenceInBinarySearchTree
