import PastaBench.leetcode.FindTheDuplicateNumber.Generated

/-!
# find-the-duplicate-number — hand-written proofs  (Medium, bucket `term`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Worked reference: `PastaBench/leetcode/SmallestEvenMultiple/Proofs.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only FindTheDuplicateNumber` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem findDuplicate_spec' : <the generated statement> := by
  <hand-written proof>

example : findDuplicate_spec = findDuplicate_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.FindTheDuplicateNumber

-- TODO: state and prove the correctness theorem for `findDuplicate`.

end PastaBench.leetcode.FindTheDuplicateNumber
