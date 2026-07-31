import PastaBench.leetcode.FindNumbersWithEvenNumberOfDigits.Generated

/-!
# find-numbers-with-even-number-of-digits — hand-written proofs  (Easy, bucket `term`)

HUMAN-WRITTEN. `pastabench.py regen` never touches this file; it only rewrites `Generated.lean`.

Worked reference: `PastaBench/leetcode/SmallestEvenMultiple/Proofs.lean`.

Workflow:
1. Add contracts (`Requires` / `Ensures` / `Invariant` / `Assert`) to `solution.py`.
2. `python3 PastaBench/pastabench.py regen --only FindNumbersWithEvenNumberOfDigits` — PastaLean states the theorem in
   `Generated.lean` and discharges what it can, leaving `sorry` for the rest.
3. Restate that theorem here and prove it by hand.

Restating keeps the human proof independent of regeneration. To guarantee the restatement did
not drift from what PastaLean generated, follow it with the fidelity check — `rfl` typechecks
only if both statements are definitionally equal:

```
theorem findNumbers_spec' : <the generated statement> := by
  <hand-written proof>

example : findNumbers_spec = findNumbers_spec' := rfl   -- statements agree
```
-/

namespace PastaBench.leetcode.FindNumbersWithEvenNumberOfDigits

-- TODO: state and prove the correctness theorem for `findNumbers`.

end PastaBench.leetcode.FindNumbersWithEvenNumberOfDigits
